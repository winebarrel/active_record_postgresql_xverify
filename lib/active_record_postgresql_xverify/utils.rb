# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  module Utils
    class << self
      def pg_connection_info(conn)
        cih = conn.conninfo_hash
        "host=#{cih[:host]}, database=#{cih[:dbname]}, username=#{cih[:user]}"
      end

      def pg_ping(conn)
        conn.query ''
        true
      rescue PG::Error
        false
      end
    end
  end
end
