# active_record_postgresql_xverify

It is a library to solve Amazon RDS failover problems.

cf. https://github.com/brianmario/mysql2/issues/948

> [!note]
> **This library does not retry queries. Just reconnect.**

[![Gem Version](https://badge.fury.io/rb/active_record_postgresql_xverify.svg)](http://badge.fury.io/rb/active_record_postgresql_xverify)
[![CI](https://github.com/winebarrel/active_record_postgresql_xverify/actions/workflows/ci.yml/badge.svg)](https://github.com/winebarrel/active_record_postgresql_xverify/actions/workflows/ci.yml)

## How it works

![](https://user-images.githubusercontent.com/117768/59006968-7ce27f80-885f-11e9-9c4a-a71ecb679c9c.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record_postgresql_xverify'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_postgresql_xverify

## Usage

```ruby
#!/usr/bin/env ruby
require 'active_record'
require 'active_record_postgresql_xverify'
require 'logger'

ActiveRecord::Base.establish_connection(
  adapter:  'postgresql',
  host:     '127.0.0.1',
  port:      5432,
  username: 'root',
  database: 'bookshelf',
)

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.formatter = proc {|_, _, _, message| "#{message}\n" }

ActiveRecordPostgresqlXverify.verify = ->(conn) do
  ping = begin
           conn.query ''
           true
         rescue PG::Error
           false
         end

  ping && false # force reconnect
end
# Default: ->(conn) do
#            begin
#              conn.query ''
#              true
#            rescue PG::Error
#              false
#            end

ActiveRecordPostgresqlXverify.handle_if = ->(config) do
  config[:host] == '127.0.0.1'
end
# Default: ->(_) { true }

ActiveRecordPostgresqlXverify.only_on_error = false
# Default: true

# postgres=> CREATE DATABASE bookshelf;
# bookshelf=> CREATE TABLE books (id INT PRIMARY KEY);
class Book < ActiveRecord::Base; end

def pg_backend_pid(model)
  conn = model.connection.instance_variable_get(:@connection) || Book.connection.instance_variable_get(:@raw_connection)
  conn.backend_pid
end

Book.count
prev_process_id = pg_backend_pid(Book)

ActiveRecord::Base.connection_handler.connection_pool_list.each(&:release_connection)

Book.count
curr_process_id = pg_backend_pid(Book)

p curr_process_id == prev_process_id #=> false
```

## Rails configuration

In `config/environments/production.rb`:

```ruby
ActiveRecordPostgresqlXverify.verify = ->(conn) do
  ping = begin
           conn.query ''
           true
         rescue PG::Error
           false
         end

  ping && conn.query('show transaction_read_only').getvalue(0, 0) == 'off'
end
# Same as below:
#   ActiveRecordPostgresqlXverify.verify = ActiveRecordPostgresqlXverify::Verifiers::AURORA_MASTER
```

## Test

```
bundle install
bundle exec appraisal install
docker-compose up -d
bundle exec appraisal ar71 rake
```

## Related links

* https://github.com/winebarrel/active_record_mysql_xverify
