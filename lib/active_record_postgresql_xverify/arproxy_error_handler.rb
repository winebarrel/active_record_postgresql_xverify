# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  class ArproxyErrorHandler < Arproxy::Base
    include ActiveRecordPostgresqlXverify::ErrorHandler
  end
end
