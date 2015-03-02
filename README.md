## Sensu-Plugins-mysql

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-mysql.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-mysql)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-mysql.svg)](http://badge.fury.io/rb/sensu-plugins-mysql)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-mysql.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-mysql)

## Functionality

## Files
 * bin/check-cloudwatch-mysql-sensu
 * bin/check-mysql-alive
 * bin/check-mysql-connections
 * bin/check-mysql-disk
 * bin/check-mysql-innodb-lock
 * bin/metrics-mysql-graphite
 * bin/metrics-mysql
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

Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install sensu-plugins-mysql -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

#### Rubygems

`gem install sensu-plugins-mysql`

#### Bundler

Add *sensu-plugins-disk-checks* to your Gemfile and run `bundle install` or `bundle update`

#### Chef

Using the Sensu **sensu_gem** LWRP
```
sensu_gem 'sensu-plugins-mysql' do
  options('--prerelease')
  version '0.0.1.alpha.4'
end
```

Using the Chef **gem_package** resource
```
gem_package 'sensu-plugins-mysql' do
  options('--prerelease')
  version '0.0.1.alpha.4'
end
```

## Notes

[1]:[https://travis-ci.org/sensu-plugins/sensu-plugins-mysql]
[2]:[http://badge.fury.io/rb/sensu-plugins-mysql]
[3]:[https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql]
[4]:[https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql]
[5]:[https://gemnasium.com/sensu-plugins/sensu-plugins-mysql]
