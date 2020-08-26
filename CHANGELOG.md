# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed [here](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md)

## [Unreleased]

## [3.2.0] - 2020-08-26
### Changed
- Bump sensu-plugin dependency from ~> 1.2 to ~> 4.0
- Updated bundler dependancy to '~> 2.1'
- Updated rubocop dependency to '~> 0.81.0'
- Remediated rubocop issues
- Updated rake dependency to '~> 13.0'

## [3.1.1] - 2019-03-04
### Fixed
- check-mysql-disk.rb: update defaults for float and integer values as a string as the defaults apparently do not execute the proc which would have properly converted it to the appropriate type (@majormoses)

## [3.1.0] - 2018-12-15
### Added
- metrics-mysql-multiple-select-countcript (@nagyt234)


## [3.0.0] - 2018-12-04
### Security
- updated rubocop dependency to `~> 0.51.0` per: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8418. (@majormoses)

### Breaking Changes
- removed < ruby 2.3 support as they are EOL (@majormoses)

### Changed
- appeased the cops (@majormoses)

## [2.7.0] - 2018-11-25
### Added
- metrics-mysql-select-count.rb script (@nagyt234)

## [2.6.0] - 2018-11-17
### Added
- check-mysql-select-count.rb: fleshed out config hash to read from ini file if specified (@fuzzy-logic-zach)

## [2.5.1] - 2018-06-21
### Fixed
- check-mysql-alive.rb: allow specifying a value for `-i` (@scones)

## [2.5.0] - 2018-06-12
### Added
- metrics-mysql-raw.rb: added `Qcache_free_memory` collection (@alchandia)

## [2.4.0] - 2018-06-4
### Added
- Add check-mysql-select-count.rb script (@negachov)

## [2.3.0] - 2018-03-17
### Added
- check-mysql-msr-replication-status.rb: new script that helps with monitoring mysql multi-source replication (@ndelic0)

### Changed
- appeased cops (@majormoses)

## [2.1.1] - 2018-02-07
### Fixed
- check-mysql-status.rb: if --socket flag is specified, it overrides config (@tinle)

## [2.2.0] - 2017-11-19
### Changed
- check-mysql-alive.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-connections.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-disk.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-innodb-lock.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-query-result-count.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-replication-status.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-status.rb: Add support for custom section in inifile. (@oba11)
- check-mysql-threads.rb: Add support for custom section in inifile. (@oba11)
- metrics-mysql-graphite.rb: Add support for custom section in inifile. (@oba11)
- metrics-mysql-processes.rb: Add support for custom section in inifile. (@oba11)
- metrics-mysql-query-result-count.rb: Add support for custom section in inifile. (@oba11)
- metrics-mysql-raw.rb: Add support for custom section in inifile. (@oba11)
- README.md: update useage to have an example using the custom ini section (@majormoses)
- update changelog guidelines location (@majormoses)

### Fixed
- misc spelling and whitespace (@majormoses)

## [2.1.2] - 2017-10-04
### Changed
- In `README` clarify why they should not use privileged users for monitoring with sensu. (@majormoses)
- In `README` add more usage examples. (@rwillmer)

### Fixed
- check-mysql-disk.rb: fixed short option `-s` to `-S` for `--socket` as it conflicted with `--size` (@2autunni)

## [2.1.1] - 2017-06-25
### Added
- Added minimum viable permissions in `README` for all the checks, metrics, and handlers. (@majormoses)

### Fixed
- check-mysql-disk.rb: make required options required. (@majormoses)

### Changed
- check-mysql-disk.rb: misc changes on where option output is cast. (@majormoses)

## [2.1.0] - 2017-06-10
### Added
- metrics-mysql-query-result-count.rb: Creates a graphite-formatted metric for the length of a result set from a MySQL query. (@athal7)

## [2.0.0] - 2017-06-05
### Breaking Change
- check-mysql-status.rb: renamed short arg of `--check` due to conflicts (@majormoses)

### Changed
- check-mysql-status.rb: made the options easier to read by splitting them across multiple lines (@majormoses)

### Added
- Add testing on Ruby 2.4 (@eheydrick)

## [1.2.1] - 2017-05-03
### Fixed
- Fix configuration for check-mysql-query-result-count.rb script (@athal7)

## [1.2.0] - 2017-03-23
- Add check-mysql-query-result-count.rb script (@athal7)

## [1.1.0] - 2017-01-15
### Added
- Added minimum thresholds to the check-mysql-threads.rb script
- Added metrics plugin with mysql gem requirement
- Added metrics plugin metrics-mysql-processes from `SHOW PROCESSLIST`
- Added fallback plugin check-mysql-status.rb with no mysql gem requirement - status and replication
- Added multi source replication parameter on check-mysql-replication-status.rb

### Fixed
- metrics-mysql-graphite.rb: Properly close mysql connection

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/3.2.0...HEAD
[3.2.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/3.1.1...3.2.0
[3.1.1]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/3.1.0...3.1.1
[3.1.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/3.0.0...3.1.0
[3.0.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.7.0...3.0.0
[2.7.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.6.0...2.7.0
[2.6.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.5.1...2.6.0
[2.5.1]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.5.0...2.5.1
[2.5.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.4.0...2.5.0
[2.4.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.2.1...2.3.0
[2.2.1]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.2.0..2.2.1
[2.2.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.1.1...2.2.0
[2.1.2]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.1.1...2.1.2
[2.1.1]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/1.2.1...2.0.0
[1.2.1]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.4...1.0.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.1...0.0.2
