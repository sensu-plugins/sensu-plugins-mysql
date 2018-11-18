#!/usr/bin/env ruby
#
# MySQL Multi-source Replication Status
# ===
#
#
#   EXAMPLE
#     check-mysql-msr-replication-status.rb -h db01 --ini '/etc/sensu/my.cnf'
#     check-mysql-msr-replication-status.rb -h db01 --ini '/etc/sensu/my.cnf' --ini-section customsection
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

class CheckMysqlMSRReplicationStatus < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h',
         long: '--host VALUE',
         description: 'Database host'

  option :port,
         short: '-P',
         long: '--port VALUE',
         description: 'Database port',
         default: 3306,
         proc: proc(&:to_i)

  option :socket,
         short: '-s SOCKET',
         long: '--socket SOCKET',
         description: 'Socket to use'

  option :user,
         short: '-u',
         long: '--username VALUE',
         description: 'Database username'

  option :pass,
         short: '-p',
         long: '--password VALUE',
         description: 'Database password'

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
         long: '--warning VALUE',
         description: 'Warning threshold for replication lag',
         default: 900,
         proc: proc(&:to_i)

  option :crit,
         short: '-c',
         long: '--critical=VALUE',
         description: 'Critical threshold for replication lag',
         default: 1800,
         proc: proc(&:to_i)

  def set_status(io_thread_status, sql_thread_status, seconds_behind_master)
    if io_thread_status == 'No' || sql_thread_status == 'No' || seconds_behind_master > config[:crit]
      2
    elsif seconds_behind_master > config[:warn] && seconds_behind_master <= config[:crit]
      1
    else
      0
    end
  end

  def run
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

    begin
      ok_statuses = []
      warn_statuses = []
      crit_statuses = []
      output = []

      db = Mysql.new(db_host, db_user, db_pass, nil, config[:port], config[:socket])
      channels = db.query('SELECT channel_name FROM performance_schema.replication_connection_status')

      channels.num_rows.times do
        channel = channels.fetch_hash
        results = db.query("SHOW SLAVE STATUS FOR CHANNEL \'#{channel['channel_name']}\'")
        results.each_hash do |row|
          io_thread_status = row['Slave_IO_Running']
          sql_thread_status = row['Slave_SQL_Running']
          seconds_behind_master = row['Seconds_Behind_Master'].to_i
          status = set_status
          message = "#{channel['channel_name']} STATES:"
          message += " Slave_IO_Running=#{io_thread_status}"
          message += ", Slave_SQL_Running=#{sql_thread_status}"
          message += ", Seconds_Behind_Master=#{seconds_behind_master}"

          if status == 0
            ok_statuses << message
          elsif status == 1
            warn_statuses << message
          elsif status == 2
            crit_statuses << message
          else
            puts 'Undefined status.'
          end
        end
      end
      output << crit_statuses unless crit_statuses.empty?
      output << warn_statuses unless warn_statuses.empty?
      output << ok_statuses unless ok_statuses.empty?

      if !crit_statuses.empty?
        critical output
      elsif !warn_statuses.empty?
        warning output
      else
        ok output
      end
    rescue Mysql::Error => e
      errstr = "Error code: #{e.errno} Error message: #{e.error}"
      errstr += "SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')
      critical errstr
    rescue StandardError => e
      critical "unhandled exception: #{e}"
    ensure
      db.close if db
    end
  end
end
