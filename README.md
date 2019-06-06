# active_record_postgresql_xverify

It is a library that performs extended verification when an error occurs when executing SQL.

[![Gem Version](https://badge.fury.io/rb/active_record_postgresql_xverify.svg)](http://badge.fury.io/rb/active_record_postgresql_xverify)
[![Build Status](https://travis-ci.org/winebarrel/active_record_postgresql_xverify.svg?branch=master)](https://travis-ci.org/winebarrel/active_record_postgresql_xverify)

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
  password: 'password',
  database: 'bookshelf',
)

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.formatter = proc {|_, _, _, message| "#{message}\n" }

ActiveRecordPostgresqlXverify.verify = ->(conn) do
  ping = begin
           conn.query 'SELECT 1'
           true
         rescue PG::Error
           false
         end

  ping && false # force reconnect
end
# Default: ->(conn) do
#            begin
#              conn.query 'SELECT 1'
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

# CREATE DATABASE bookshelf;
# CREATE TABLE bookshelf.books (id INT PRIMARY KEY);
class Book < ActiveRecord::Base; end

Book.count
prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

ActiveRecord::Base.connection_handler.connection_pool_list.each(&:release_connection)

Book.count
curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

p curr_process_id == prev_process_id #=> false
```

## Rails configuration

In `config/environments/production.rb`:

```ruby
ActiveRecordPostgresqlXverify.verify = ->(conn) do
  ping = begin
           conn.query 'SELECT 1'
           true
         rescue PG::Error
           false
         end

  ping && conn.query('show transaction_read_only')
              .first.fetch('transaction_read_only') == 'off'
end
# Same as below:
#   ActiveRecordPostgresqlXverify.verify = ActiveRecordPostgresqlXverify::Verifiers::AURORA_MASTER
```

## Test

```
bundle install
bundle exec appraisal install
docker-compose up -d
bundle exec appraisal ar52 rake
```

## Related links

* https://github.com/winebarrel/activerecord-mysql-reconnect
