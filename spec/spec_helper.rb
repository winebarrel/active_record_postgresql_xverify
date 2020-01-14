# frozen_string_literal: true

require 'bundler/setup'
require 'active_record'
require 'active_record_postgresql_xverify'
require 'model/book.rb'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :all do
    conn_spec = {
      adapter: 'postgresql',
      host: '127.0.0.1',
      username: 'postgres',
      password: 'postgres',
      database: 'bookshelf',
      port: 12_345,
    }

    ActiveRecord::Base.establish_connection(conn_spec)

    pg_params = {
      host: conn_spec.fetch(:host),
      port: conn_spec.fetch(:port),
      user: conn_spec.fetch(:username),
      password: conn_spec.fetch(:password),
    }

    begin
      PG.connect(pg_params.merge(dbname: 'postgres')).query('CREATE DATABASE bookshelf')
    rescue PG::DuplicateDatabase # rubocop:disable Lint/SuppressedException
    end

    @pg = PG.connect(pg_params.merge(dbname: conn_spec.fetch(:database)))
    @pg.query('DROP TABLE IF EXISTS books')

    begin
      @pg.query('CREATE TABLE books (id INT PRIMARY KEY)')
    rescue PG::DuplicateTable # rubocop:disable Lint/SuppressedException
    end
  end
end

module SpecHelper
  def active_record_release_connections
    ActiveRecord::Base.connection_handler.connection_pool_list.each(&:release_connection)
  end

  def pg_backend_pid(model)
    model.connection.query('select pg_backend_pid()').first.fetch(0)
  end

  def pid_changes(model)
    prev_process_id = pg_backend_pid(model)
    active_record_release_connections
    yield
    curr_process_id = pg_backend_pid(model)
    expect(curr_process_id).to_not eq prev_process_id
  end

  def pid_does_not_change(model)
    prev_process_id = pg_backend_pid(model)
    active_record_release_connections
    yield
    curr_process_id = pg_backend_pid(model)
    expect(curr_process_id).to eq prev_process_id
  end
end
include SpecHelper # rubocop:disable Style/MixinUsage
