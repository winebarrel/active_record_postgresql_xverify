# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  module Verifiers
    AURORA_MASTER = lambda do |conn|
      ping = begin
               conn.query 'SELECT 1'
               true
             rescue PG::Error
               false
             end

      ping && conn.query('show transaction_read_only')
                  .first.fetch('transaction_read_only') == 'off'
    end
  end
end
