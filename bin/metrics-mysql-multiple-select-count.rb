#!/usr/bin/env ruby
#
# MySQL Select Count Metric
#
# Creates a graphite-formatted metric for the first value of a result set from a MySQL query.
#
# Copyright 2017 Andrew Thal <athal7@me.com>
# Copyright 2018 Tibor Nagy <nagyt@hu.inter.net>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'mysql'
require 'inifile'
require 'json'

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
         description: 'MySQL password'

  option :database,
         short: '-d DATABASE',
         long: '--database DATABASE',
         description: 'MySQL database',
         default: ''

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

  option :name,
         short: '-n NAME',
         long: '--name NAME',
         description: 'Metric name for a configured handler',
         default: 'mysql.query_count'

  option :query,
         short: '-q SELECT_COUNT_QUERY',
         long: '--query SELECT_COUNT_QUERY',
         description: 'Queries to execute in JSON',
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

    begin
      query_hash = ::JSON.parse config[:query]
    rescue ::JSON::ParserError => e
      critical "JSON.parse error: #{e}"
    end

    # traverse all SQL
    query_hash.each do |key, sql|
      raise "invalid query : #{sql}" unless sql =~ /^select\s+count\(\s*\*\s*\)/i

      db = Mysql.real_connect(config[:host], db_user, db_pass, config[:database], config[:port], config[:socket])
      count = db.query(sql).fetch_row[0].to_i

      output "#{config[:name]}.#{key}", count
    end

    ok

  rescue Mysql::Error => e
    errstr = "Error code: #{e.errno} Error message: #{e.error}"
    critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')

  rescue StandardError => e
    critical "unhandled exception: #{e}"

  end
end
