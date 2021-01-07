# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  module ErrorHandler
    def execute(*)
      super
    rescue StandardError
      _flag_extend_verify!
      raise
    end

    def execute_and_clear(*, **)
      super
    rescue StandardError
      _flag_extend_verify!
      raise
    end

    def _flag_extend_verify!
      Thread.current[ActiveRecordPostgresqlXverify::EXTEND_VERIFY_FLAG] = true
    end
  end
end
