# frozen_string_literal: true

module DiscourseEvents
  class Logger
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def info(message)
      log(:info, message)
    end

    def error(message)
      log(:error, message)
    end

    def log(level, message)
      Log.create(context: context.to_s, level: level.to_s, message: message)
    end
  end
end
