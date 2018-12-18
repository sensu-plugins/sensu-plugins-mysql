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
#require_relative './spec_helper.rb'

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
    ['Yes', 'Yes',    0, 0, 'ok'],
    ['No',  'Yes',  nil, 2, 'critical'],
    ['Yes', 'No',   nil, 2, 'critical'],
    ['No',  'No',   nil, 2, 'critical'],
    ['Yes', 'Yes',  899, 0, 'ok'],
    ['Yes', 'Yes',  900, 1, 'warning'],
    ['Yes', 'Yes', 1799, 1, 'warning'],
    ['Yes', 'Yes', 1800, 2, 'critical'],
  ].each do |testdata|
    it "returns #{testdata[4]} for default thresholds" do
      slave_status_row = {
        "Slave_IO_State" => '',
        "Slave_IO_Running" => testdata[0],
        "Slave_SQL_Running" => testdata[1],
        "Last_IO_Error" => '',
        "Last_SQL_Error" => '',
        "Seconds_Behind_Master" => testdata[2]
      }
      begin
        allow(checker).to receive(:open_connection) # do nothing
        allow(checker).to receive(:query_slave_status).and_return slave_status_row
        checker.run
      rescue SystemExit => e
        exit_code = e.status
      end
      expect(exit_code).to eq testdata[3]
    end
  end
end
