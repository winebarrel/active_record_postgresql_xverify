# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  module Utils
    class << self
      def pg_connection_info(conn)
        cih = conn.conninfo_hash
        "host=#{cih[:host]}, database=#{cih[:dbname]}, username=#{cih[:user]}"
      end
    end
  end
end
