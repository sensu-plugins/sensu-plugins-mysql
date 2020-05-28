#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Push mysql stats into graphite
# ===
#
# NOTE: This plugin will attempt to get replication stats but the user
# must have SUPER or REPLICATION CLIENT privileges to run 'SHOW SLAVE
# STATUS'. It will silently ignore and continue if 'SHOW SLAVE STATUS'
# fails for any reason. The key 'slaveLag' will not be present in the
# output.
#
# Copyright 2012 Pete Shima <me@peteshima.com>
# Additional hacks by Joe Miller - https://github.com/joemiller
# Updated by Oluwaseun Obajobi 2014 to accept ini argument
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# USING INI ARGUMENT
# This was implemented to load mysql credentials without parsing the username/password.
# The ini file should be readable by the sensu user/group.
# Ref: http://eric.lubow.org/2009/ruby/parsing-ini-files-with-ruby/
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

require 'sensu-plugin/metric/cli'
require 'mysql'
require 'socket'
require 'inifile'

class MysqlGraphite < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Mysql Host to connect to',
         required: true

  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'Mysql Port to connect to',
         proc: proc(&:to_i),
         default: 3306

  option :username,
         short: '-u USERNAME',
         long: '--user USERNAME',
         description: 'Mysql Username'

  option :password,
         short: '-p PASSWORD',
         long: '--pass PASSWORD',
         description: 'Mysql password',
         default: ''

  option :ini,
         short: '-i',
         long: '--ini VALUE',
         description: 'My.cnf ini file'

  option :ini_section,
         description: 'Section in my.cnf ini file',
         long: '--ini-section VALUE',
         default: 'client'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.mysql"

  option :socket,
         short: '-S SOCKET',
         long: '--socket SOCKET'

  option :verbose,
         short: '-v',
         long: '--verbose',
         boolean: true

  def metrics_hash
    {
      'general' => {
        'Bytes_received' => 'rxBytes',
        'Bytes_sent' => 'txBytes',
        'Key_read_requests' => 'keyRead_requests',
        'Key_reads' => 'keyReads',
        'Key_write_requests' => 'keyWrite_requests',
        'Key_writes' => 'keyWrites',
        'Binlog_cache_use' => 'binlogCacheUse',
        'Binlog_cache_disk_use' => 'binlogCacheDiskUse',
        'Max_used_connections' => 'maxUsedConnections',
        'Aborted_clients' => 'abortedClients',
        'Aborted_connects' => 'abortedConnects',
        'Threads_connected' => 'threadsConnected',
        'Open_files' => 'openFiles',
        'Open_tables' => 'openTables',
        'Opened_tables' => 'openedTables',
        'Prepared_stmt_count' => 'preparedStmtCount',
        'Seconds_Behind_Master' => 'slaveLag',
        'Select_full_join' => 'fullJoins',
        'Select_full_range_join' => 'fullRangeJoins',
        'Select_range' => 'selectRange',
        'Select_range_check' => 'selectRange_check',
        'Select_scan' => 'selectScan',
        'Slow_queries' => 'slowQueries'
      },
      'querycache' => {
        'Qcache_queries_in_cache' => 'queriesInCache',
        'Qcache_hits' => 'cacheHits',
        'Qcache_inserts' => 'inserts',
        'Qcache_not_cached' => 'notCached',
        'Qcache_lowmem_prunes' => 'lowMemPrunes'
      },
      'commands' => {
        'Com_admin_commands' => 'admin_commands',
        'Com_begin' => 'begin',
        'Com_change_db' => 'change_db',
        'Com_commit' => 'commit',
        'Com_create_table' => 'create_table',
        'Com_drop_table' => 'drop_table',
        'Com_show_keys' => 'show_keys',
        'Com_delete' => 'delete',
        'Com_create_db' => 'create_db',
        'Com_grant' => 'grant',
        'Com_show_processlist' => 'show_processlist',
        'Com_flush' => 'flush',
        'Com_insert' => 'insert',
        'Com_purge' => 'purge',
        'Com_replace' => 'replace',
        'Com_rollback' => 'rollback',
        'Com_select' => 'select',
        'Com_set_option' => 'set_option',
        'Com_show_binlogs' => 'show_binlogs',
        'Com_show_databases' => 'show_databases',
        'Com_show_fields' => 'show_fields',
        'Com_show_status' => 'show_status',
        'Com_show_tables' => 'show_tables',
        'Com_show_variables' => 'show_variables',
        'Com_update' => 'update',
        'Com_drop_db' => 'drop_db',
        'Com_revoke' => 'revoke',
        'Com_drop_user' => 'drop_user',
        'Com_show_grants' => 'show_grants',
        'Com_lock_tables' => 'lock_tables',
        'Com_show_create_table' => 'show_create_table',
        'Com_unlock_tables' => 'unlock_tables',
        'Com_alter_table' => 'alter_table'
      },
      'counters' => {
        'Handler_write' => 'handlerWrite',
        'Handler_update' => 'handlerUpdate',
        'Handler_delete' => 'handlerDelete',
        'Handler_read_first' => 'handlerRead_first',
        'Handler_read_key' => 'handlerRead_key',
        'Handler_read_next' => 'handlerRead_next',
        'Handler_read_prev' => 'handlerRead_prev',
        'Handler_read_rnd' => 'handlerRead_rnd',
        'Handler_read_rnd_next' => 'handlerRead_rnd_next',
        'Handler_commit' => 'handlerCommit',
        'Handler_rollback' => 'handlerRollback',
        'Handler_savepoint' => 'handlerSavepoint',
        'Handler_savepoint_rollback' => 'handlerSavepointRollback'
      },
      'innodb' => {
        'Innodb_buffer_pool_pages_total' =>        'bufferTotal_pages',
        'Innodb_buffer_pool_pages_free' =>         'bufferFree_pages',
        'Innodb_buffer_pool_pages_dirty' =>        'bufferDirty_pages',
        'Innodb_buffer_pool_pages_data' =>         'bufferUsed_pages',
        'Innodb_buffer_pool_pages_flushed' =>      'bufferFlushed_pages',
        'Innodb_buffer_pool_pages_misc' =>         'bufferMisc_pages',
        'Innodb_buffer_pool_bytes_data' =>         'bufferUsed_bytes',
        'Innodb_buffer_pool_bytes_dirty' =>        'bufferDirty_bytes',
        'Innodb_buffer_pool_read_ahead_rnd' =>     'bufferReadAheadRnd',
        'Innodb_buffer_pool_read_ahead' =>         'bufferReadAhead',
        'Innodb_buffer_pool_read_ahead_evicted' => 'bufferReadAheadEvicted',
        'Innodb_buffer_pool_read_requests' =>      'bufferReadRequests',
        'Innodb_buffer_pool_reads' =>              'bufferReads',
        'Innodb_buffer_pool_wait_free' =>          'bufferWaitFree',
        'Innodb_buffer_pool_write_requests' =>     'bufferWriteRequests',
        'innodb_buffer_pool_size' =>               'poolSize',
        'Innodb_page_size' =>                      'pageSize',
        'Innodb_pages_created' =>                  'pagesCreated',
        'Innodb_pages_read' =>                     'pagesRead',
        'Innodb_pages_written' =>                  'pagesWritten',
        'Innodb_row_lock_current_waits' =>         'currentLockWaits',
        'Innodb_row_lock_waits' =>                 'lockWaitTimes',
        'Innodb_row_lock_time' =>                  'rowLockTime',
        'Innodb_data_reads' =>                     'fileReads',
        'Innodb_data_writes' =>                    'fileWrites',
        'Innodb_data_fsyncs' =>                    'fileFsyncs',
        'Innodb_log_writes' =>                     'logWrites',
        'Innodb_rows_updated' =>                   'rowsUpdated',
        'Innodb_rows_read' =>                      'rowsRead',
        'Innodb_rows_deleted' =>                   'rowsDeleted',
        'Innodb_rows_inserted' =>                  'rowsInserted',
      },
      'configuration' => {
        'max_connections'         =>          'MaxConnections',
        'Max_prepared_stmt_count' =>          'MaxPreparedStmtCount',
      },
      'cluster' => {
        'wsrep_last_committed' => 'last_committed',
        'wsrep_replicated' => 'replicated',
        'wsrep_replicated_bytes' => 'replicated_bytes',
        'wsrep_received' => 'received',
        'wsrep_received_bytes' => 'received_bytes',
        'wsrep_local_commits' => 'local_commits',
        'wsrep_local_cert_failures' => 'local_cert_failures',
        'wsrep_local_bf_aborts' => 'local_bf_aborts',
        'wsrep_local_replays' => 'local_replays',
        'wsrep_local_send_queue' => 'local_send_queue',
        'wsrep_local_send_queue_avg' => 'local_send_queue_avg',
        'wsrep_local_recv_queue' => 'local_recv_queue',
        'wsrep_local_recv_queue_avg' => 'local_recv_queue_avg',
        'wsrep_flow_control_paused' => 'flow_control_paused',
        'wsrep_flow_control_sent' => 'flow_control_sent',
        'wsrep_flow_control_recv' => 'flow_control_recv',
        'wsrep_cert_deps_distance' => 'cert_deps_distance',
        'wsrep_apply_oooe' => 'apply_oooe',
        'wsrep_apply_oool' => 'apply_oool',
        'wsrep_apply_window' => 'apply_window',
        'wsrep_commit_oooe' => 'commit_oooe',
        'wsrep_commit_oool' => 'commit_oool',
        'wsrep_commit_window' => 'commit_window',
        'wsrep_local_state' => 'local_state',
        'wsrep_cert_index_size' => 'cert_index_size',
        'wsrep_causal_reads' => 'causal_reads',
        'wsrep_cluster_conf_id' => 'cluster_conf_id',
        'wsrep_cluster_size' => 'cluster_size',
        'wsrep_local_index' => 'local_index',
        'wsrep_evs_repl_latency' => 'evs_repl_latency'
      }
    }
  end
  
  def fix_and_output_evs_repl_latency_data(row, mysql_shorthostname, category)
    # see https://github.com/codership/galera/issues/67 for documentation on field mappings
    data = row['Value'].split('/')
    output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.wsrep_evs_repl_latency_min", data[0]
    output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.wsrep_evs_repl_latency_avg", data[1]
    output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.wsrep_evs_repl_latency_max", data[2]
    output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.wsrep_evs_repl_latency_stddev", data[3]
    output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.wsrep_evs_repl_latency_samplesize", data[4]
  end

  def run
    # props to https://github.com/coredump/hoardd/blob/master/scripts-available/mysql.coffee

    metrics = metrics_hash

    # FIXME: break this up
    config[:host].split(' ').each do |mysql_host| # rubocop:disable Metrics/BlockLength
      mysql_shorthostname = mysql_host.tr('.', '_')
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
        mysql = Mysql.new(mysql_host, db_user, db_pass, nil, config[:port], config[:socket])

        results = mysql.query('SHOW GLOBAL STATUS')
      rescue StandardError => e
        puts e.message
      end

      results.each_hash do |row|
      # special handling for wsrep_evs_repl_latency as this contains forward slash delimited data
      fix_and_output_evs_repl_latency_data(row) if row['Variable_name'] == 'wsrep_evs_repl_latency'
        metrics.each do |category, var_mapping|
          if var_mapping.key?(row['Variable_name'])
            if row['Variable_name'] == 'wsrep_evs_repl_latency'
              fix_and_output_evs_repl_latency_data(row, mysql_shorthostname, category)
            else
              output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.#{var_mapping[row['Variable_name']]}", row['Value']
            end
          end
        end
      end

      begin
        slave_results = mysql.query('SHOW SLAVE STATUS')
        # should return a single element array containing one hash
        # #YELLOW
        slave_results.fetch_hash.each_pair do |key, value|
          if metrics['general'].include?(key)
            # Replication lag being null is bad, very bad, so negativate it here
            value = -1 if key == 'Seconds_Behind_Master' && value.nil?
            output "#{config[:scheme]}.#{mysql_shorthostname}.general.#{metrics['general'][key]}", value
          end
        end
      rescue StandardError => e
        puts "Error querying slave status: #{e}" if config[:verbose]
      end

      begin
        variables_results = mysql.query('SHOW GLOBAL VARIABLES')

        category = 'configuration'
        variables_results.each_hash do |row|
          metrics[category].each do |metric, desc|
            if metric.casecmp(row['Variable_name']).zero?
              output "#{config[:scheme]}.#{mysql_shorthostname}.#{category}.#{desc}", row['Value']
            end
          end
        end
      rescue StandardError => e
        puts e.message
      end

      mysql&.close
    end

    ok
  end
end
