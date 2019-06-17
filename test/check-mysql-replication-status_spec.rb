#!/usr/bin/env ruby
#
#   check-mysql-replication-status_spec
#
# DESCRIPTION:
#  rspec tests for check-mysql-replication-status
#
# OUTPUT:
#   RSpec testing output: passes and failures info
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   rspec
#
# USAGE:
#   For Rspec Testing
#
# NOTES:
#   For Rspec Testing
#
# LICENSE:
#   Copyright 2018 Jan Kunzmann, Erasys GmbH <jan.kunzmann@erasys.de>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require_relative '../bin/check-mysql-replication-status'
require_relative './spec_helper.rb'

# rubocop:disable Metrics/BlockLength
describe CheckMysqlReplicationStatus do
  let(:checker) { described_class.new }
  let(:exit_code) { nil }

  before(:each) do
    def checker.ok(*_args)
      exit 0
    end

    def checker.warning(*_args)
      exit 1
    end

    def checker.critical(*_args)
      exit 2
    end
  end

  [
    # IO Thread status | SQL Thread status | Lag | Expected exit code | Expected reporting level
    ['Yes', 'Yes', 0, 0, :ok],
    ['No',  'Yes', nil, 2, :critical],
    ['Yes', 'No', nil, 2, :critical],
    ['No',  'No',  nil, 2, :critical],
    ['Yes', 'Yes', 900, 0, :ok],
    ['Yes', 'Yes', 901, 1, :warning],
    ['Yes', 'Yes', 1800, 1, :warning],
    ['Yes', 'Yes', 1801, 2, :critical],
  ].each do |testdata|
    it "returns #{testdata[4]} for default thresholds" do
      slave_status_row = {
        'Slave_IO_State' => '',
        'Slave_IO_Running' => testdata[0],
        'Slave_SQL_Running' => testdata[1],
        'Last_IO_Error' => '',
        'Last_SQL_Error' => '',
        'Seconds_Behind_Master' => testdata[2]
      }
      allow(checker).to receive(:open_connection) # do nothing
      allow(checker).to receive(:query_slave_status).and_return slave_status_row
      expect(checker).to receive(testdata[4]).once.and_call_original
      begin
        checker.run
      rescue SystemExit => e
        exit_code = e.status
      end
      expect(exit_code).to eq testdata[3]
    end
  end

  [
    # Lag after outlier | Configured reporting level | Exit code | Expected reporting level | Expected message
    [0, :ok, 0, :ok, 'slave running: true, replication delayed by 0, with max. outlier at 100000'],
    [99_999, :ok, 2, :critical, 'replication delayed by 99999, with max. outlier at 100000'],
    [0, :critical, 2, :critical, 'replication delayed by 0, with max. outlier at 100000'],
  ].each do |testdata|
    it "sleeps with lag outlier protection and returns #{testdata[3]} (using default thresholds)" do
      checker.config[:lag_outlier_retry] = 1
      checker.config[:lag_outlier_sleep] = 10
      checker.config[:lag_outlier_report] = testdata[1]

      slave_status_row = [
        {
          'Slave_IO_State' => '',
          'Slave_IO_Running' => 'Yes',
          'Slave_SQL_Running' => 'Yes',
          'Last_IO_Error' => '',
          'Last_SQL_Error' => '',
          'Seconds_Behind_Master' => 100_000
        },
        {
          'Slave_IO_State' => '',
          'Slave_IO_Running' => 'Yes',
          'Slave_SQL_Running' => 'Yes',
          'Last_IO_Error' => '',
          'Last_SQL_Error' => '',
          'Seconds_Behind_Master' => testdata[0]
        }
      ]

      allow(checker).to receive(:open_connection) # do nothing
      allow(checker).to receive(:query_slave_status).and_return slave_status_row[0], slave_status_row[1]
      expect(checker).to receive(:sleep).with(10)
      expect(checker).to receive(testdata[3]).with(testdata[4]).once.and_call_original
      begin
        checker.run
      rescue SystemExit => e
        exit_code = e.status
      end
      expect(exit_code).to eq testdata[2]
    end
  end
end
