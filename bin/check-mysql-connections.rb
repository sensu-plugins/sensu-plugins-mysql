#!/usr/bin/env ruby
# frozen_string_literal: false

#
# MySQL Health Plugin
# ===
#
# This plugin counts the maximum connections your MySQL has reached and warns you according to specified limits
#
# Copyright 2012 Panagiotis Papadomitsos <pj@ezgr.net>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'mysql'
require 'inifile'

class CheckMySQLHealth < Sensu::Plugin::Check::CLI
  option :user,
         description: 'MySQL User',
         short: '-u USER',
         long: '--user USER',
         default: 'root'

  option :password,
         description: 'MySQL Password',
         short: '-p PASS',
         long: '--password PASS'

  option :ini,
         description: 'My.cnf ini file',
         short: '-i',
         long: '--ini VALUE'

  option :ini_section,
         description: 'Section in my.cnf ini file',
         long: '--ini-section VALUE',
         default: 'client'

  option :hostname,
         description: 'Hostname to login to',
         short: '-h HOST',
         long: '--hostname HOST',
         default: 'localhost'

  option :port,
         description: 'Port to connect to',
         short: '-P PORT',
         long: '--port PORT',
         default: '3306'

  option :socket,
         description: 'Socket to use',
         short: '-s SOCKET',
         long: '--socket SOCKET'

  option :maxwarn,
         description: "Number of connections upon which we'll issue a warning",
         short: '-w NUMBER',
         long: '--warnnum NUMBER',
         default: 100

  option :maxcrit,
         description: "Number of connections upon which we'll issue an alert",
         short: '-c NUMBER',
         long: '--critnum NUMBER',
         default: 128

  option :usepc,
         description: 'Use percentage of defined max connections instead of absolute number',
         short: '-a',
         long: '--percentage',
         default: false

  option :default_charset,
         short: '-D',
         long: '--default_charset=VALUE',
         description: 'Provide custom charset for connection'

  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini[config[:ini_section]]
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:user]
      db_pass = config[:password]
    end
    db = Mysql.init
    if config[:default_charset]
      db.options Mysql::SET_CHARSET_NAME, config[:default_charset]
    end
    db.real_connect(config[:hostname], db_user, db_pass, config[:database], config[:port].to_i, config[:socket])
    max_con = db
              .query("SHOW VARIABLES LIKE 'max_connections'")
              .fetch_hash
              .fetch('Value')
              .to_i
    used_con = db
               .query("SHOW GLOBAL STATUS LIKE 'Threads_connected'")
               .fetch_hash
               .fetch('Value')
               .to_i
    if config[:usepc]
      pc = used_con.fdiv(max_con) * 100
      critical "Max connections reached in MySQL: #{used_con} out of #{max_con}" if pc >= config[:maxcrit].to_i
      warning "Max connections reached in MySQL: #{used_con} out of #{max_con}" if pc >= config[:maxwarn].to_i
      ok "Max connections is under limit in MySQL: #{used_con} out of #{max_con}" # rubocop:disable Style/IdenticalConditionalBranches
    else
      critical "Max connections reached in MySQL: #{used_con} out of #{max_con}" if used_con >= config[:maxcrit].to_i
      warning "Max connections reached in MySQL: #{used_con} out of #{max_con}" if used_con >= config[:maxwarn].to_i
      ok "Max connections is under limit in MySQL: #{used_con} out of #{max_con}" # rubocop:disable Style/IdenticalConditionalBranches
    end
  rescue Mysql::Error => e
    critical "MySQL check failed: #{e.error}"
  ensure
    db&.close
  end
end
