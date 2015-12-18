## Sensu-Plugins-mysql

[ ![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-mysql.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-mysql)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-mysql.svg)](http://badge.fury.io/rb/sensu-plugins-mysql)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mysql)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-mysql.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-mysql)
[![Codeship Status for sensu-plugins/sensu-plugins-mysql](https://codeship.com/projects/266116c0-e896-0132-af9a-62885e5c211b/status?branch=master)](https://codeship.com/projects/82837)

## Functionality

## Files
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

**metrics-mysql-graphite** example:
```bash
/opt/sensu/embedded/bin$ /opt/sensu/embedded/bin/ruby metrics-mysql-graphite.rb --host=localhost --port=3306 --user=collectd --pass=tflypass --socket=/data/mysql.sock
```

**check-mysql-connections** example
```bash
/opt/sensu/embedded/bin$ /opt/sensu/embedded/bin/ruby check-mysql-connections.rb --host=localhost --port=3306 --user=collectd --pass=tflypass --socket=/data/mysql.sock
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
The ruby executables are install in path similar to `/opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugins-mysql-0.0.4/bin`

## Troubleshooting
When used in `chef`, if the dependencies are missing, an error may abort the chef-client run: 
```bash
*** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of
necessary libraries and/or headers.  Check the mkmf.log file for more
details.  You may need configuration options.
```
This may be fixed by installing the mysql client library before the plugin:
```ruby
# http://serverfault.com/questions/415392/install-mysql-gem-for-use-in-chef-client
package "libmysqlclient-dev" do
  action :install
end

sensu_gem 'sensu-plugins-mysql' do version '0.0.4' end

```
