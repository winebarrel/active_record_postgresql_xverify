# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  module Verifier
    def active?
      if _extend_verify?
        is_active = begin
          verifier = ActiveRecordPostgresqlXverify.verify
          verifier.call(@connection)
        rescue StandardError => e
          ActiveRecordPostgresqlXverify.logger.warn("Connection verification failed: #{_build_verify_error_message(e)}")
          false
        ensure
          Thread.current[ActiveRecordPostgresqlXverify::EXTEND_VERIFY_FLAG] = false
        end

        unless is_active
          ActiveRecordPostgresqlXverify.logger.info(
            "Invalid connection: #{ActiveRecordPostgresqlXverify::Utils.pg_connection_info(@connection)}"
          )
        end

        is_active
      else
        super
      end
    end

    def _build_verify_error_message(e)
      "cause: #{e.message} [#{e.class}, " + ActiveRecordPostgresqlXverify::Utils.pg_connection_info(@connection)
    end

    def _extend_verify?
      handle_if = ActiveRecordPostgresqlXverify.handle_if
      (Thread.current[ActiveRecordPostgresqlXverify::EXTEND_VERIFY_FLAG] || !ActiveRecordPostgresqlXverify.only_on_error) && handle_if.call(@config)
    end
  end
end
