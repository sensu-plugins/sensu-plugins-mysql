#!/usr/bin/env ruby
#
#   check-mysql-threads.rb
#
# DESCRIPTION:
#   MySQL Threads Health plugin
#   This plugin evaluates the number of MySQL running threads and warns you according to specified limits
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   All
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   check-mysql-threads.rb -w [threshold] -c [threshold]
#
# NOTES:
#
# LICENSE:
#   Author: Guillaume Lefranc <guillaume@mariadb.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

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
         description: "Number of running threads upon which we'll issue a warning",
         short: '-w NUMBER',
         long: '--warnnum NUMBER',
         default: 20

  option :maxcrit,
         description: "Number of running threads upon which we'll issue an alert",
         short: '-c NUMBER',
         long: '--critnum NUMBER',
         default: 25

  def run
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['client']
      db_user = section['user']
      db_pass = section['password']
    else
      db_user = config[:user]
      db_pass = config[:password]
    end
    db = Mysql.real_connect(config[:hostname], db_user, db_pass, config[:database], config[:port].to_i, config[:socket])
    run_thr = db
               .query("SHOW GLOBAL STATUS LIKE 'Threads_running'")
               .fetch_hash
               .fetch('Value')
               .to_i
    critical "MySQL currently running threads: #{run_thr}" if run_thr >= config[:maxcrit].to_i
    warning "MySQL currently running threads: #{run_thr}" if run_thr >= config[:maxwarn].to_i
    ok "Currently running threads are under limit in MySQL: #{run_thr}"
   rescue Mysql::Error => e
  critical "MySQL check failed: #{e.error}"
ensure
  db.close if db
  end
end
