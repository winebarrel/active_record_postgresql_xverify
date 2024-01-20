# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  module Verifiers
    AURORA_MASTER = lambda do |conn|
      ActiveRecordPostgresqlXverify::Utils.pg_ping(conn) &&
        conn.query('show transaction_read_only').getvalue(0, 0) == 'off'
    end
  end
end
