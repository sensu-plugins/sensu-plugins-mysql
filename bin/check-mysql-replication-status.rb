#!/usr/bin/env ruby
#
# MySQL Replication Status (modded from disk)
# ===
#
# Copyright 2011 Sonian, Inc <chefs@sonian.net>
# Updated by Oluwaseun Obajobi 2014 to accept ini argument
# Updated by Nicola Strappazzon 2016 to implement Multi Source Replication
# Refactored by Jan Kunzmann (Erasys GmbH) 2018
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# USING INI ARGUMENT
# This was implemented to load mysql credentials without parsing the username/password.
# The ini file should be readable by the sensu user/group.
# Ref: http://eric.lubow.org/2009/ruby/parsing-ini-files-with-ruby/
#
#   EXAMPLE
#     mysql-alive.rb -h db01 --ini '/etc/sensu/my.cnf'
#     mysql-alive.rb -h db01 --ini '/etc/sensu/my.cnf' --ini-section customsection
#
#   MY.CNF INI FORMAT
#   [client]
#   user=sensu
#   password="abcd1234"
#
#   [customsection]
#   user=user
#   password="password"
#

require 'sensu-plugin/check/cli'
require 'mysql'
require 'inifile'

class CheckMysqlReplicationStatus < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h',
         long: '--host=VALUE',
         description: 'Database host'

  option :port,
         short: '-P',
         long: '--port=VALUE',
         description: 'Database port',
         default: 3306,
         # #YELLOW
         proc: lambda { |s| s.to_i } # rubocop:disable Lambda

  option :socket,
         short: '-s SOCKET',
         long: '--socket SOCKET',
         description: 'Socket to use'

  option :user,
         short: '-u',
         long: '--username=VALUE',
         description: 'Database username'

  option :pass,
         short: '-p',
         long: '--password=VALUE',
         description: 'Database password'

  option :master_connection,
         short: '-m',
         long: '--master-connection=VALUE',
         description: 'Replication master connection name'

  option :ini,
         short: '-i',
         long: '--ini VALUE',
         description: 'My.cnf ini file'

  option :ini_section,
         description: 'Section in my.cnf ini file',
         long: '--ini-section VALUE',
         default: 'client'

  option :warn,
         short: '-w',
         long: '--warning=VALUE',
         description: 'Warning threshold for replication lag',
         default: 900,
         # #YELLOW
         proc: lambda { |s| s.to_i } # rubocop:disable Lambda

  option :crit,
         short: '-c',
         long: '--critical=VALUE',
         description: 'Critical threshold for replication lag',
         default: 1800,
         # #YELLOW
         proc: lambda { |s| s.to_i } # rubocop:disable Lambda

  def detect_replication_status?(row)
    %w[
      Slave_IO_State
      Slave_IO_Running
      Slave_SQL_Running
      Last_IO_Error
      Last_SQL_Error
      Seconds_Behind_Master
    ].all? { |key| row.key? key }
  end

  def slave_running?(row)
    %w[
      Slave_IO_Running
      Slave_SQL_Running
    ].all? { |key| row[key] =~ /Yes/ }
  end

  def open_connection
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini[config[:ini_section]]
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:user]
      db_pass = config[:pass]
    end
    db_host = config[:host]

    if [db_host, db_user, db_pass].any?(&:nil?)
      unknown 'Must specify host, user, password'
    end

    Mysql.new(db_host, db_user, db_pass, nil, config[:port], config[:socket])
  end

  def query_slave_status(db)
    db_conn = config[:master_connection]

    sql = if db_conn.nil?
            'SHOW SLAVE STATUS'
          else
            "SHOW SLAVE '#{db_conn}' STATUS"
          end
    result = db.query sql
    return nil if result.nil?

    rows = result.fetch_hash
    return nil if rows.empty?

    rows
  end

  def broken_slave_message(row)
    db_conn = config[:master_connection]

    running = if db_conn.nil?
                'Slave not running!'
              else
                "Slave on master connection #{db_conn} not running!"
              end

    "#{running} STATES: " + [
      "Slave_IO_Running=#{row['Slave_IO_Running']}",
      "Slave_SQL_Running=#{row['Slave_SQL_Running']}",
      "LAST ERROR: #{row['Last_SQL_Error']}"
    ].join(', ')
  end

  def ok_slave_message
    db_conn = config[:master_connection]

    if db_conn.nil?
      "slave running: true"
    else
      "master connection: #{db_conn}, slave running: true"
    end
  end

  def run
    db = open_connection

    row = query_slave_status(db)
    ok 'show slave status was nil. This server is not a slave.' if row.nil?
    warn "couldn't detect replication status" unless detect_replication_status?(row)

    slave_running = slave_running?(row)
    critical broken_slave_message(row) unless slave_running

    replication_delay = row['Seconds_Behind_Master'].to_i
    message = "replication delayed by #{replication_delay}"
    # TODO (breaking change): Thresholds are exclusive which is not consistent with all other checks
    critical message if replication_delay > config[:crit]
    warning message if replication_delay > config[:warn]
    ok "#{ok_slave_message}, #{message}"
  rescue Mysql::Error => e
    errstr = "Error code: #{e.errno} Error message: #{e.error}"
    critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')
  rescue StandardError => e
    critical e
  ensure
    db.close if db
  end
end
