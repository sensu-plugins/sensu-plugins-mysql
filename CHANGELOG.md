#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
### Added
- added check-mysql-threads.rb script
- changed metrics-mysql-graphite.rb to use mysql / ruby-mysql gem
### Changed
- removed --help option as it comes from opt parser

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

##0.0.1 - 2015-05-29
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.4...HEAD
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-mysql/compare/0.0.1...0.0.2
