# frozen_string_literal: true

require 'logger'
require 'active_support'
require 'active_record_postgresql_xverify/version'
require 'active_record_postgresql_xverify/constants'
require 'active_record_postgresql_xverify/logger'
require 'active_record_postgresql_xverify/utils'
require 'active_record_postgresql_xverify/config'
require 'active_record_postgresql_xverify/error_handler'
require 'active_record_postgresql_xverify/verifier'
require 'active_record_postgresql_xverify/verifiers/aurora_master'

ActiveSupport.on_load :active_record do
  require 'active_record/connection_adapters/postgresql_adapter'
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend ActiveRecordPostgresqlXverify::ErrorHandler
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend ActiveRecordPostgresqlXverify::Verifier
end
