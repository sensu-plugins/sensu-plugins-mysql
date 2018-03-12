#!/usr/bin/env ruby
#
# MySQL MultiSource Replication Status
# ===
#
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
    db_conn = config[:master_connection]

    if [db_host, db_user, db_pass].any?(&:nil?)
      unknown 'Must specify host, user, password'
    end

    begin
	
	  okStatuses = Array.new
      warnStatuses = Array.new
      critStatuses = Array.new
      output = Array.new
	  
      db = Mysql.new(db_host, db_user, db_pass, nil, config[:port], config[:socket])
	  channels = db.query("SELECT channel_name FROM performance_schema.replication_connection_status")
	  n_channels = channels.num_rows
	  
	  n_channles.times do
	      channel = channels.fetch_row.to_s
		  results = con.query("SHOW SLAVE STATUS FOR CHANNEL \'#{channel}\'")
		  
		  results.each_hash do |row|
		      ioThreadStatus = row['Slave_IO_Running']
              sqlThreadStatus = row['Slave_SQL_Running']
              secondsBehindMaster = row['Seconds_Behind_Master'].to_i
              status = 0
			  
			  if ioThreadStatus == 'No' || sqlThreadStatus == 'No' || secondsBehindMaster > config[:crit]
			      status = 2
			  end
			  
			  if secondsBehindMaster > config[:warn] &&
			      secondsBehindMaster <= config[:crit]
			      status = 1
			  end
			  
			  message += "#{channel} STATES:"
			  message += " Slave_IO_Running=#{ioThreadStatus}"
			  message += ", Slave_SQL_Running=#{sqlThreadStatus}"
			  message += ", Seconds_Behind_Master=#{secondsBehindMaster}\n"
			  
          	#  message = "#{channel}=io:#{ioThreadStatus},sql:#{sqlThreadStatus},behind:#{secondsBehindMaster}\n"
			  if status == 0
			      okStatuses << message
			  elsif
			      warnStatuses << message
			  elsif
			      critStatuses << message
			  else
			      puts "Undefined status."
			  end
		  end
	  
	  end
	  
	  output << critStatuses if critStatuses.length > 0
      output << warnStatuses if warnStatuses.length > 0
      output << okStatuses  if okStatuses.length > 0
	  
	  if critStatuses.length > 0
	      critical output
	  elsif warnStatuses.length > 0
	      warning output
	  else
	      ok output
	  end
	  
      

    rescue Mysql::Error => e
      errstr = "Error code: #{e.errno} Error message: #{e.error}"
      critical "#{errstr} SQLSTATE: #{e.sqlstate}" if e.respond_to?('sqlstate')

    rescue => e
      critical e

    ensure
      db.close if db
    end
  end
end
