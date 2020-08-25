#!/usr/bin/env ruby
# frozen_string_literal: false

#
# MySQL Query Result Count Check
#
# Checks the length of a result set from a MySQL query.
#
# Copyright 2017 Andrew Thal <athal7@me.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'mysql'
require 'inifile'

class MysqlQueryCountCheck < Sensu::Plugin::Check::CLI
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
         description: 'MySQL password',
         default: ''

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
         short: '-w COUNT',
         long: '--warning COUNT',
         description: 'COUNT warning threshold for number of items returned by the query',
         proc: proc(&:to_i),
         required: true

  option :crit,
         short: '-c COUNT',
         long: '--critical COUNT',
         description: 'COUNT critical threshold for number of items returned by the query',
         proc: proc(&:to_i),
         required: true

  option :query,
         short: '-q QUERY',
         long: '--query QUERY',
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
    db = Mysql.real_connect(config[:host], db_user, db_pass, config[:database], config[:port].to_i, config[:socket])
    length = db.query(config[:query]).count

    if length >= config[:crit]
      critical "Result count is above the CRITICAL limit: #{length} length / #{config[:crit]} limit"
    elsif length >= config[:warn]
      warning "Result count is above the WARNING limit: #{length} length / #{config[:warn]} limit"
    else
      ok 'Result count length is below thresholds'
    end
  rescue Mysql::Error => e
    errstr = "Error code: #{e.errno} Error message: #{e.error}"
    critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')
  rescue StandardError => e
    critical e
  ensure
    db&.close
  end
end
