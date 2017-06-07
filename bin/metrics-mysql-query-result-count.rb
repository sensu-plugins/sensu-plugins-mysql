#!/usr/bin/env ruby
#
# MySQL Query Result Count Metric
#
# Creates a graphite-formatted metric for the length of a result set from a MySQL query.
#
# Copyright 2017 Andrew Thal <athal7@me.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'mysql'
require 'inifile'

class MysqlQueryCountMetric < Sensu::Plugin::Metric::CLI::Graphite
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
         default: ''

  option :ini,
         short: '-i',
         long: '--ini VALUE',
         description: 'My.cnf ini file'

  option :socket,
         short: '-S SOCKET',
         long: '--socket SOCKET',
         description: 'MySQL Unix socket to connect to'

  option :name,
         short: '-n NAME',
         long: '--name NAME',
         description: 'Metric name for a configured handler',
         default: 'mysql.query_count'

  option :query,
         short: '-q QUERY',
         long: '--query QUERY',
         description: 'Query to execute',
         required: true

  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['client']
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:username]
      db_pass = config[:password]
    end
    db = Mysql.real_connect(config[:host], db_user, db_pass, config[:database], config[:port].to_i, config[:socket])
    length = db.query(config[:query]).count

    output config[:name], length
    ok

  rescue Mysql::Error => e
    errstr = "Error code: #{e.errno} Error message: #{e.error}"
    critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')

  rescue => e
    critical e

  ensure
    db.close if db
  end
end
