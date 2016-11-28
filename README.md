## Sensu-Plugins-mysql

[ ![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-mysql.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-mysql)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-mysql.svg)](http://badge.fury.io/rb/sensu-plugins-mysql)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-mysql.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-mysql)
[![Codeship Status for sensu-plugins/sensu-plugins-mysql](https://codeship.com/projects/266116c0-e896-0132-af9a-62885e5c211b/status?branch=master)](https://codeship.com/projects/82837)

## Functionality

## Files
 * bin/check-mysql-status.rb
 * bin/metrics-mysql-raw.rb
 * bin/check-cloudwatch-mysql-sensu.rb
 * bin/check-mysql-alive.rb
 * bin/check-mysql-connections.rb
 * bin/check-mysql-disk.rb
 * bin/check-mysql-innodb-lock.rb
 * bin/metrics-mysql-graphite.rb
 * bin/metrics-mysql.rb
 * bin/mysql-metrics.sql

## Usage

**metrics-mysql**
```
{
    "mysql":{
        "hostname": "localhost",
        "username": "sensu_user",
        "password": "sensu_user_pass"
    }
}
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
