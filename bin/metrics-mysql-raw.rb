#!/usr/bin/env ruby
#
# MySQL Alive Status Plugin
# ===
#
# This plugin attempts to login to mysql with provided credentials.
# Author: Modified (metrics-mysql-graphite) by Magic Online to use bash instead of mysql gem
# Date: September 2016
# This allows to not use dependencies like mysql-devel 
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# USING INI ARGUMENT
# This was implemented to load mysql credentials without parsing the username/password.
# The ini file should be readable by the sensu user/group.
#
#   EXAMPLE
#     check-mysql-status.rb -h localhost --ini '/etc/sensu/my.cnf' --database test
#
#   MY.CNF INI FORMAT
#   [client]
#   user=sensu
#   password="abcd1234"
#   socket="/var/lib/mysql/mysql.sock"

require 'open3'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'inifile'


class MetricsMySQLRaw < Sensu::Plugin::Metric::CLI::Graphite
	option :user,
		description: 'MySQL User',
		short: '-u USER',
		long: '--user USER',
		default: 'mosim'

	option :password,
		description: 'MySQL Password',
		short: '-p PASS',
		long: '--password PASS',
		default: 'mysqlPassWord'

	option :ini,
		description: 'My.cnf ini file',
		short: '-i',
		long: '--ini VALUE'

	option :hostname,
		description: 'Hostname to login to',
		short: '-h HOST',
		long: '--hostname HOST',
		default: 'localhost'

	option :database,
		description: 'Database schema to connect to',
		short: '-d DATABASE',
		long: '--database DATABASE',
		default: 'test'

	option :port,
		description: 'Port to connect to',
		short: '-P PORT',
		long: '--port PORT',
		default: '3306'

	option :socket,
		description: 'Socket to use',
		short: '-s SOCKET',
		long: '--socket SOCKET',
		default: '/var/run/mysqld/mysqld.sock'

	option :binary,
		description: 'Absolute path to mysql binary',
		short: '-b BINARY',
		long: '--binary BINARY',
		default: 'mysql'

	option :check,
		description: 'type of check: metric',
		short: '-c CHECK',
		long: '--check CHECK',
		default: 'metric'

	option :scheme,
		description: 'Metric naming scheme, text to prepend to metric',
		short: '-s SCHEME',
		long: '--scheme SCHEME',
		default: "#{Socket.gethostname}.mysql"

	option :verbose,
		short: '-v',
		long: '--verbose',
		boolean: true

	option :off,
		description: 'Turn Metrics OFF',
		long: '--off',
		boolean: false

	def run
		ok "Metrics deactivated by user using option --off" if config[:off] == true
		metrics = {
			'general' => {
				'Bytes_received' =>         'rxBytes',
				'Bytes_sent' =>             'txBytes',
				'Key_read_requests' =>      'keyRead_requests',
				'Key_reads' =>              'keyReads',
				'Key_write_requests' =>     'keyWrite_requests',
				'Key_writes' =>             'keyWrites',
				'Binlog_cache_use' =>       'binlogCacheUse',
				'Binlog_cache_disk_use' =>  'binlogCacheDiskUse',
				'Max_used_connections' =>   'maxUsedConnections',
				'Aborted_clients' =>        'abortedClients',
				'Aborted_connects' =>       'abortedConnects',
				'Threads_connected' =>      'threadsConnected',
				'Open_files' =>             'openFiles',
				'Open_tables' =>            'openTables',
				'Opened_tables' =>          'openedTables',
				'Prepared_stmt_count' =>    'preparedStmtCount',
				'Seconds_Behind_Master' =>  'slaveLag',
				'Select_full_join' =>       'fullJoins',
				'Select_full_range_join' => 'fullRangeJoins',
				'Select_range' =>           'selectRange',
				'Select_range_check' =>     'selectRange_check',
				'Select_scan' =>            'selectScan',
				'Slow_queries' =>           'slowQueries'
			},
			'querycache' => {
				'Qcache_queries_in_cache' =>  'queriesInCache',
				'Qcache_hits' =>              'cacheHits',
				'Qcache_inserts' =>           'inserts',
				'Qcache_not_cached' =>        'notCached',
				'Qcache_lowmem_prunes' =>     'lowMemPrunes'
			},
			'commands' => {
				'Com_admin_commands' => 'admin_commands',
				'Com_begin' =>          'begin',
				'Com_change_db' =>      'change_db',
				'Com_commit' =>         'commit',
				'Com_create_table' =>   'create_table',
				'Com_drop_table' =>     'drop_table',
				'Com_show_keys' =>      'show_keys',
				'Com_delete' =>         'delete',
				'Com_create_db' =>      'create_db',
				'Com_grant' =>          'grant',
				'Com_show_processlist' => 'show_processlist',
				'Com_flush' =>          'flush',
				'Com_insert' =>         'insert',
				'Com_purge' =>          'purge',
				'Com_replace' =>        'replace',
				'Com_rollback' =>       'rollback',
				'Com_select' =>         'select',
				'Com_set_option' =>     'set_option',
				'Com_show_binlogs' =>   'show_binlogs',
				'Com_show_databases' => 'show_databases',
				'Com_show_fields' =>    'show_fields',
				'Com_show_status' =>    'show_status',
				'Com_show_tables' =>    'show_tables',
				'Com_show_variables' => 'show_variables',
				'Com_update' =>         'update',
				'Com_drop_db' =>        'drop_db',
				'Com_revoke' =>         'revoke',
				'Com_drop_user' =>      'drop_user',
				'Com_show_grants' =>    'show_grants',
				'Com_lock_tables' =>    'lock_tables',
				'Com_show_create_table' => 'show_create_table',
				'Com_unlock_tables' =>  'unlock_tables',
				'Com_alter_table' =>    'alter_table'
			},
			'counters' => {
				'Handler_write' =>              'handlerWrite',
				'Handler_update' =>             'handlerUpdate',
				'Handler_delete' =>             'handlerDelete',
				'Handler_read_first' =>         'handlerRead_first',
				'Handler_read_key' =>           'handlerRead_key',
				'Handler_read_next' =>          'handlerRead_next',
				'Handler_read_prev' =>          'handlerRead_prev',
				'Handler_read_rnd' =>           'handlerRead_rnd',
				'Handler_read_rnd_next' =>      'handlerRead_rnd_next',
				'Handler_commit' =>             'handlerCommit',
				'Handler_rollback' =>           'handlerRollback',
				'Handler_savepoint' =>          'handlerSavepoint',
				'Handler_savepoint_rollback' => 'handlerSavepointRollback'
			},
			'innodb' => {
				'Innodb_buffer_pool_pages_total' =>   'bufferTotal_pages',
				'Innodb_buffer_pool_pages_free' =>    'bufferFree_pages',
				'Innodb_buffer_pool_pages_dirty' =>   'bufferDirty_pages',
				'Innodb_buffer_pool_pages_data' =>    'bufferUsed_pages',
				'Innodb_page_size' =>                 'pageSize',
				'Innodb_pages_created' =>             'pagesCreated',
				'Innodb_pages_read' =>                'pagesRead',
				'Innodb_pages_written' =>             'pagesWritten',
				'Innodb_row_lock_current_waits' =>    'currentLockWaits',
				'Innodb_row_lock_waits' =>            'lockWaitTimes',
				'Innodb_row_lock_time' =>             'rowLockTime',
				'Innodb_data_reads' =>                'fileReads',
				'Innodb_data_writes' =>               'fileWrites',
				'Innodb_data_fsyncs' =>               'fileFsyncs',
				'Innodb_log_writes' =>                'logWrites',
				'Innodb_rows_updated' =>              'rowsUpdated',
				'Innodb_rows_read' =>                 'rowsRead',
				'Innodb_rows_deleted' =>              'rowsDeleted',
				'Innodb_rows_inserted' =>             'rowsInserted'
			},
			'configuration' => {
				'Max_prepared_stmt_count' =>          'MaxPreparedStmtCount'
			}
		}

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
		if config[:check] == "metric"
			mysql_shorthostname = config[:hostname].gsub('.','_')
			begin
				table = Array.new
				cmd = "#{config[:binary]} -u #{db_user} -h #{config[:hostname]} --port #{config[:port]} --socket #{db_socket} -p\"#{db_pass.chomp}\" --batch --disable-column-names -e 'SHOW GLOBAL STATUS;'"
				stdout, stderr, status = Open3.capture3(cmd)
				puts status.to_s.split(" ")[3] if config[:verbose]
				if status == 0
					puts "#{status}" if config[:verbose]
					stdout.split("\n").each do |row|
						line = row.gsub("\t",":")
						key = line.split(":")[0]
						value = line.split(":")[1]
						table.push('Variable_name' => key,  'Value' => value)
					end
				else
					critical "Error message: status: #{status}"
				end
				table.each do |row|
					metrics.each do |category, var_mapping|
						row_var_name = "#{row['Variable_name']}"
						var_mapping.keys.each do |vmkey|
							if "#{row_var_name}" == "#{vmkey}" && !"#{mysql_shorthostname}".chomp.empty?
								output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.#{vmkey[row_var_name]}", row['Value']
							end
						end
					end
				end

				begin
					# Slave status here
					# should return a single element array containing one hash
					# #YELLOW
					slave_results = Hash["a" => 100, "b" => 200]
					slave_results.first.each do |key, value|
						if metrics['general'].include?(key)
							# Replication lag being null is bad, very bad, so negativate it here
							value = -1 if key == 'Seconds_Behind_Master' && value.nil?
							output "#{config[:scheme]}.#{mysql_shorthostname}.general.#{metrics['general'][key]}", value
						end
					end
				rescue => e
					puts "Error querying slave status: #{e}" if config[:verbose]
				end

				begin
					table = Array.new
					cmd = "#{config[:binary]} -u #{db_user} -h #{config[:hostname]} --port #{config[:port]} --socket #{db_socket} -p\"#{db_pass.chomp}\" --batch --disable-column-names -e 'SHOW GLOBAL VARIABLES;'"
					stdout, stderr, status = Open3.capture3(cmd)
					puts status.to_s.split(" ")[3] if config[:verbose]
					if status == 0
						puts "#{status}" if config[:verbose]
						stdout.split("\n").each do |row|
							line = row.gsub("\t",":")
							key = line.split(":")[0]
							value = line.split(":")[1]
							table.push('Variable_name' => key,  'Value' => value)
						end
					else
						critical "Error message: Global variables -  status: #{status}"
					end
					##########################
					variables_results = table
					category = 'configuration'
					variables_results.each do |row|
						metrics[category].each do |metric, desc|
							if metric.casecmp(row['Variable_name']) == 0
								output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.#{desc}", row['Value']
							end
						end
					end
					######################################################
				rescue => e
					puts e.message
				end
			rescue => e
				critical "Error message: status: #{status} | Exception: #{e.message} #{e.backtrace}"
			ensure
				ok ''
				puts ''
			end
		end
		unknown 'No check type succeeded. Check your options'
	end
end
