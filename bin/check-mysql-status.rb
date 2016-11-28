#!/usr/bin/env ruby
#
# MySQL Status Plugin
# ===
#
# This plugin attempts to login to mysql with provided credentials.
# NO DEPENDENCIES (no mysql-devel and no implicit mysql-server restart)
# It checks whether MySQL is UP --check status
# It checks replication delay --check replication
# Author: Magic Online - www.magic.fr
# Date: September 2016
#
# Author: Magic Online - www.magic.fr - September 2016
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# USING INI ARGUMENT
# The ini file should be readable by the sensu user/group.
#
#   EXAMPLE
#     check-mysql-status.rb -h localhost --ini '/etc/sensu/my.cnf' --check status
#     check-mysql-status.rb -h localhost --ini '/etc/sensu/my.cnf' --check replication
#
#   MY.CNF INI FORMAT
#   [client]
#   user=sensu
#   password="abcd1234"
#   socket="/var/lib/mysql/mysql.sock"
#

require 'sensu-plugin/check/cli'
require 'inifile'
require 'open3'

# Check MySQL Status
class CheckMySQLStatus < Sensu::Plugin::Check::CLI
  option :user, description: 'MySQL User', short: '-u USER', long: '--user USER', default: 'mosim'
  option :password, description: 'MySQL Password', short: '-p PASS', long: '--password PASS', default: 'mysqlPassWord'
  option :ini, description: 'My.cnf ini file', short: '-i', long: '--ini VALUE'
  option :hostname, description: 'Hostname to login to', short: '-h HOST', long: '--hostname HOST', default: 'localhost'
  option :database, description: 'Database schema to connect to', short: '-d DATABASE', long: '--database DATABASE', default: 'test'
  option :port, description: 'Port to connect to', short: '-P PORT', long: '--port PORT', default: '3306'
  option :socket, description: 'Socket to use', short: '-s SOCKET', long: '--socket SOCKET', default: '/var/run/mysqld/mysqld.sock'
  option :binary, description: 'Absolute path to mysql binary', short: '-b BINARY', long: '--binary BINARY', default: 'mysql'
  option :check, description: 'type of check: status | replication', short: '-c CHECK', long: '--check CHECK', default: 'status'
  option :warn, short: '-w', long: '--warning=VALUE', description: 'Warning threshold for replication lag', default: 900, proc: lambda { |s| s.to_i }
  option :crit, short: '-c', long: '--critical=VALUE', description: 'Critical threshold for replication lag', default: 1800, proc: lambda { |s| s.to_i }
  option :debug, description: 'Print debug info', long: '--debug', default: false

  def credentials
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['client']
      db_user = section['user']
      db_pass = section['password']
      db_socket = section['socket']
    else
      db_user = config[:user]
      db_pass = config[:password]
      db_socket = config[:socket]
    end
    return db_user, db_pass, db_socket
  end

  def run
    db_user, db_pass, db_socket = credentials
    if config[:check] == 'status'
      begin
        cmd = "#{config[:binary]} -u #{db_user} -h #{config[:hostname]} --port #{config[:port]} \
        --socket #{db_socket} -p\"#{db_pass.strip}\" --batch --disable-column-names -e 'show schemas;'"
        stdout, _stderr, status = Open3.capture3(cmd)
        if status.to_i == 0
          ok "#{status} | #{stdout.split("\n")}"
        else
          critical "Error message: status: #{status}"
        end
      rescue => e
        critical "Error message: status: #{status} | Exception: #{e}"
      ensure
        puts ''
      end
    end
    if config[:check] == 'replication'
      table = {}
      begin
        cmd = "#{config[:binary]} -u #{db_user} -h #{config[:hostname]} --port #{config[:port]} \
        --socket #{db_socket} -p\"#{db_pass.strip}\"  -e 'SHOW SLAVE STATUS\\G'"
        stdout, _stderr, status = Open3.capture3(cmd)
        if status.to_i != 0
          critical "Error message: status: #{status}"
        end
        stdout.split("\n").each do |line|
          key = line.split(':')[0]
          value = line.split(':')[1]
          table[key.strip.to_s] = value.to_s unless key.include? '***'
        end
        dict = []
        table.keys.to_a.each do |k|
          %w(Slave_IO_State Slave_IO_Running Slave_SQL_Running Last_IO_Error Last_SQL_Error Seconds_Behind_Master).each do |key|
            dict.push(k.strip.to_s) if key.strip == k.strip
          end
        end
        table.each do |attribute, value|
          puts "#{attribute} : #{value}" if config[:debug]
          warn "couldn't detect replication status :#{dict.size}" unless dict.size == 6
          slave_running = %w(Slave_IO_Running Slave_SQL_Running).all? do |key|
            table[key].to_s =~ /Yes/
          end
          output = 'Slave not running!'
          output += ' STATES:'
          output += " Slave_IO_Running=#{table['Slave_IO_Running']}"
          output += ", Slave_SQL_Running=#{table['Slave_SQL_Running']}"
          output += ", LAST ERROR: #{table['Last_SQL_Error']}"
          critical output unless slave_running
          replication_delay = table['Seconds_Behind_Master'].to_i
          message = "replication delayed by #{replication_delay}"
          if replication_delay > config[:warn] && replication_delay <= config[:crit]
            warning message
          elsif replication_delay >= config[:crit]
            critical message
          else
            ok "slave running: #{slave_running}, #{message}"
          end
        end
        ok 'show slave status was nil. This server is not a slave.'
      rescue => e
        critical "Error message: status: #{status} | Exception: #{e}"
      end
    end
    unknown 'No check type succeeded. Check your options'
  end
end
