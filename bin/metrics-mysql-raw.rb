#!/usr/bin/env ruby
#
# MySQL metrics Plugin without mysql gem requirement
# ===
#
# This plugin attempts to login to mysql with provided credentials.
# and outputs metrics in graphite format
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# USING INI ARGUMENT
# This was implemented to load mysql credentials without parsing
# the username/password.
# The ini file should be readable by the sensu user/group.
#
#   EXAMPLE
#     metrics-mysql-raw.rb -h localhost --ini '/etc/sensu/my.cnf'
#     metrics-mysql-raw.rb -h localhost --ini '/etc/sensu/my.cnf' --ini-section customsection
#
#   MY.CNF INI FORMAT
#   [client]
#   user=sensu
#   password="abcd1234"
#   socket="/var/lib/mysql/mysql.sock"
#
#   [customsection]
#   user=user
#   password="password"
#
# LICENSE:
#  Copyright 2012 Pete Shima <me@peteshima.com>
#   Additional hacks by Joe Miller - https://github.com/joemiller
#   Updated by Oluwaseun Obajobi 2014 to accept ini argument
#   Forked by Magic Online 11.2016 to not depend on mysql gem
#   - www.magic.fr <hanynowsky@gmail.com>
#   MIT - Same as Sensu License
#

require 'sensu-plugin/metric/cli'
require 'open3'
require 'socket'
require 'inifile'
require 'timeout'

#
# Metrics Mysql Raw
#
class MetricsMySQLRaw < Sensu::Plugin::Metric::CLI::Graphite
  option(
    :user,
    description: 'MySQL User',
    short: '-u USER',
    long: '--user USER',
    default: 'mosim'
  )

  option(
    :password,
    description: 'MySQL Password',
    short: '-p PASS',
    long: '--password PASS',
    default: 'mysqlPassWord'
  )

  option(
    :ini,
    description: 'My.cnf ini file',
    short: '-i',
    long: '--ini VALUE'
  )

  option(
    :ini_section,
    description: 'Section in my.cnf ini file',
    long: '--ini-section VALUE',
    default: 'client'
  )

  option(
    :hostname,
    description: 'Hostname to login to',
    short: '-h HOST',
    long: '--hostname HOST',
    default: 'localhost'
  )

  option(
    :database,
    description: 'Database schema to connect to. NOT YET IMPlemented',
    short: '-d DATABASE',
    long: '--database DATABASE',
    default: 'test'
  )

  option(
    :timeout,
    description: 'Timeout',
    short: '-T TIMEOUT',
    long: '--timeout TIMEOUT',
    default: 10
  )

  option(
    :port,
    description: 'Port to connect to',
    short: '-P PORT',
    long: '--port PORT',
    default: '3306'
  )

  option(
    :socket,
    description: 'Socket to use',
    short: '-s SOCKET',
    long: '--socket SOCKET',
    default: '/var/run/mysqld/mysqld.sock'
  )

  option(
    :binary,
    description: 'Absolute path to mysql binary',
    short: '-b BINARY',
    long: '--binary BINARY',
    default: 'mysql'
  )

  option(
    :check,
    description: 'type of check: metric',
    short: '-c CHECK',
    long: '--check CHECK',
    default: 'metric'
  )

  option(
    :scheme,
    description: 'Metric naming scheme, text to prepend to metric',
    short: '-s SCHEME',
    long: '--scheme SCHEME',
    default: "#{Socket.gethostname}.mysql"
  )

  option(
    :verbose,
    short: '-v',
    long: '--verbose',
    boolean: true
  )

  option(
    :off,
    description: 'Turn Metrics OFF',
    long: '--off',
    boolean: true,
    default: false
  )

  # Metrics hash
  def metrics_hash
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
        'Slow_queries' =>           'slowQueries',
      },
      'querycache' => {
        'Qcache_queries_in_cache' =>  'queriesInCache',
        'Qcache_hits' =>              'cacheHits',
        'Qcache_inserts' =>           'inserts',
        'Qcache_not_cached' =>        'notCached',
        'Qcache_lowmem_prunes' =>     'lowMemPrunes',
        'Qcache_free_memory' =>       'freeMemory',
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
        'Com_alter_table' =>    'alter_table',
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
        'Handler_savepoint_rollback' => 'handlerSavepointRollback',
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
        'Innodb_rows_inserted' =>             'rowsInserted',
      },
      'configuration' => {
        'Max_prepared_stmt_count' =>          'MaxPreparedStmtCount',
      },
    }
    metrics
  end

  # Credentials
  def credentials
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini[config[:ini_section]]
      db_user = section['user']
      db_pass = section['password']
      db_socket = section['socket']
    else
      db_user = config[:user]
      db_pass = config[:password]
      db_socket = config[:socket]
    end
    [db_user, db_pass, db_socket]
  end

  # Slave metrics
  def slave_metrics(metrics)
    # should return a single element array containing one hash
    # #YELLOW
    mysql_shorthostname = config[:hostname].tr('.', '_')
    slave_results = Hash['a' => 100, 'b' => 200]
    slave_results.first.each do |key, value|
      if metrics['general'].include?(key)
        # Replication lag being null is bad, very bad, so negativate it here
        value = -1 if key == 'Seconds_Behind_Master' && value.nil?
        output "#{config[:scheme]}.#{mysql_shorthostname}.general.#{metrics['general'][key]}", value
      end
    end
  rescue StandardError => e
    puts "Error querying slave status: #{e}" if config[:verbose]
  end

  # Configuration metrics
  def configuration_metrics(metrics, db_user, db_pass, db_socket)
    mysql_shorthostname = config[:hostname].tr('.', '_')
    table = []
    cmd = "#{config[:binary]} -u #{db_user} -h #{config[:hostname]} \
--port #{config[:port]} --socket #{db_socket} -p\"#{db_pass.chomp}\" --batch \
--disable-column-names -e 'SHOW GLOBAL VARIABLES;'"
    stdout, _stderr, status = Open3.capture3(cmd)
    puts status.to_s.split(' ')[3] if config[:verbose]
    if status == 0
      puts status.to_s if config[:verbose]
      stdout.split("\n").each do |row|
        line = row.tr("\t", ':')
        key = line.split(':')[0]
        value = line.split(':')[1]
        table.push('Variable_name' => key, 'Value' => value)
      end
    else
      critical "Error message: Global variables -  status: #{status}"
    end
    variables_results = table
    category = 'configuration'
    variables_results.each do |row|
      metrics[category].each do |metric, desc|
        if metric.casecmp(row['Variable_name']) == 0
          output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.#{desc}", row['Value']
        end
      end
    end
  rescue StandardError => e
    puts e.message
  end

  # Fetch MySQL metrics
  def fetcher(db_user, db_pass, db_socket)
    metrics = metrics_hash
    # FIXME: this needs refactoring
    if config[:check] == 'metric' # rubocop:disable Style/GuardClause
      mysql_shorthostname = config[:hostname].tr('.', '_')
      begin
        table = []
        cmd = "#{config[:binary]} -u #{db_user} -h #{config[:hostname]} \
--port #{config[:port]} --socket #{db_socket} -p\"#{db_pass.chomp}\" --batch \
--disable-column-names -e 'SHOW GLOBAL STATUS;'"
        stdout, _stderr, status = Open3.capture3(cmd)
        puts status.to_s.split(' ')[3] if config[:verbose]
        if status == 0
          puts status.to_s if config[:verbose]
          stdout.split("\n").each do |row|
            line = row.tr("\t", ':')
            key = line.split(':')[0]
            value = line.split(':')[1]
            table.push('Variable_name' => key, 'Value' => value)
          end
        else
          critical "Error message: status: #{status}"
        end
        table.each do |row|
          metrics.each do |category, var_mapping|
            row_var_name = row['Variable_name'].to_s
            var_mapping.each_key do |vmkey|
              if row_var_name.to_s == vmkey.to_s
                prefix = "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.#{vmkey[row_var_name]}"
                output prefix, row['Value'] unless mysql_shorthostname.to_s.chomp.empty?
              end
            end
          end
        end
        # Slave and configuration metrics here
        slave_metrics(metrics)
        configuration_metrics(metrics, db_user, db_pass, db_socket)
      rescue StandardError => e
        critical "Error message: status: #{status} | Exception: #{e.backtrace}"
      ensure
        ok ''
      end
    end
  end

  # Main Function
  def run
    ok 'Metrics deactivated by user using option --off' if config[:off] == true
    begin
      Timeout.timeout(config[:timeout]) do
        fetcher(credentials[0], credentials[1], credentials[2])
      end
    rescue Timeout::Error => e
      unknown "Timed out #{e.message}"
    end
    unknown 'Did not succeed to retrieve MySQL metrics. Check your options'
  end
end
