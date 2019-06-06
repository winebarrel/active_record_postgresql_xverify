# frozen_string_literal: true

module ActiveRecordPostgresqlXverify
  @config = {
    handle_if: ->(_) { true },
    only_on_error: true,
    verify: ->(conn) { ActiveRecordPostgresqlXverify::Utils.pg_ping(conn) },
  }

  class << self
    def handle_if=(proc)
      @config[:handle_if] = proc
    end

    def handle_if
      @config.fetch(:handle_if)
    end

    def verify=(proc)
      @config[:verify] = proc
    end

    def verify
      @config.fetch(:verify)
    end

    def only_on_error=(bool)
      @config[:only_on_error] = bool
    end

    def only_on_error
      @config.fetch(:only_on_error)
    end
  end
end
