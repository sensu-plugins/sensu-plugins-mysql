#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
## Added
- added minimum thresholds to the check-mysql-threads.rb script

## [1.1.1] - 2016-10-13
### Added
- Fix short multi source replication on check-mysql-replication-status.rb

## [1.1.0] - 2016-10-05
### Added
- added multi source replication parameter on check-mysql-replication-status.rb

## [1.0.0] - 2016-08-15
### Added
- added check-mysql-threads.rb script
- changed metrics-mysql-graphite.rb to use mysql / ruby-mysql gem

### Changed
- Removed compatibility with Ruby 1.9
- Updated sensu-plugin dependency from `= 1.2.0` to `~> 1.2`
- removed --help option as it comes from opt parser

### Removed
- check-cloudwatch-mysql-sensu.rb - sensu-plugins-aws check-cloudwatch-metric.rb should be used

## [0.0.4] - 2015-08-04
### Changed
- updated sensu-plugin gem to 1.2.0

## [0.0.3] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

### Added
- ability to read configuration data from an ini file

## [0.0.2] - 2015-06-03
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## 0.0.1 - 2015-05-29
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/1.0.0...HEAD
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.4...1.0.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.1...0.0.2
