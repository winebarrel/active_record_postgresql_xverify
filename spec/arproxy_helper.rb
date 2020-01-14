# frozen_string_literal: true

if ENV['ARPROXY'] == '1'
  require 'active_record_postgresql_xverify_for_arproxy'

  class TestArproxyProxy < Arproxy::Base
    def execute(sql, name = nil)
      super(sql, name)
    end
  end

  Arproxy.configure do |config|
    config.adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    config.use TestArproxyProxy
    config.use ActiveRecordPostgresqlXverify::ArproxyErrorHandler
  end

  Arproxy.enable!
else
  require 'active_record_postgresql_xverify'
end
