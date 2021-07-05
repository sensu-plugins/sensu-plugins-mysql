#!/usr/bin/env ruby
#
# MySQL Select Count Check
#
# Checks the length of a result set from a MySQL query.
#
# Copyright 2017 Andrew Thal <athal7@me.com> to check-mysql-query-result-count.rb
# Modified by Mutsutoshi Yoshimoto <negachov@gmail.com> 2018 to select count(*) version
# Modified by Jan Kunzmann <jan-github@phobia.de> 2018 to select value version
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'mysql'
require 'inifile'

class MysqlSelectCountCheck < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'MySQL Host to connect to',
         required: true

  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'MySQL Port to connect to',
         proc: proc(&:to_i),
         default: 3306

  option :username,
         short: '-u USERNAME',
         long: '--user USERNAME',
         description: 'MySQL Username'

  option :password,
         short: '-p PASSWORD',
         long: '--pass PASSWORD',
         description: 'MySQL password'

  option :database,
         short: '-d DATABASE',
         long: '--database DATABASE',
         description: 'MySQL database',
         required: true

  option :ini,
         short: '-i',
         long: '--ini VALUE',
         description: 'My.cnf ini file'

  option :ini_section,
         description: 'Section in my.cnf ini file',
         long: '--ini-section VALUE',
         default: 'client'

  option :socket,
         short: '-S SOCKET',
         long: '--socket SOCKET',
         description: 'MySQL Unix socket to connect to'

  option :warn,
         short: '-w VALUE',
         long: '--warning VALUE',
         description: 'Warning when query value exceeds threshold',
         proc: proc(&:to_f),
         required: true

  option :crit,
         short: '-c VALUE',
         long: '--critical VALUE',
         description: 'Critical when query value exceeds threshold',
         proc: proc(&:to_f),
         required: true

  option :query,
         short: '-q SELECT_VALUE_QUERY',
         long: '--query SELECT_VALUE_QUERY',
         description: 'Query to execute',
         required: true


  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini[config[:ini_section]]
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:username]
      db_pass = config[:password]
    end

    db = Mysql.real_connect(config[:host], db_user, db_pass, config[:database], config[:port], config[:socket])

    rs = db.query(config[:query])
    fields = rs.fetch_fields
    col_name = fields[0].name.capitalize

    value = rs.fetch_row[0].to_f

    if config[:crit] > config[:warn]
      beyond = "above"
      beneath = "below"
      factor = 1.0
    else
      beyond = "below"
      beneath = "above"
      factor = -1.0
    end

    if value * factor >= config[:crit] * factor
      critical "#{col_name} #{value} is #{beyond} the CRITICAL limit of #{config[:crit]}"
    elsif value * factor >= config[:warn] * factor
      warning "#{col_name} #{value} is #{beyond} the WARNING limit of #{config[:warn]}"
    else
      ok "#{col_name} #{value} is #{beneath} thresholds"
    end

  rescue Mysql::Error => e
    errstr = "Error code: #{e.errno} Error message: #{e.error}"
    critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')

  rescue StandardError => e
    critical "Unhandled exception: #{e}"

  ensure
    db.close if db
  end
end
