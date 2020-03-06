# frozen_string_literal: true

module GRPCWeb::Metrics
  PREFIX = 'grpc_web_ruby.'

  # Support for when DogStatsD is not used
  class Empty
    def increment(name, opts = {}); end

    def timing(_name, _opts = {}, &block)
      block&.call
    end

    def method_missing(_m, *_args, &block)
      block&.call
    end
  end

  class DogStatsD
    attr_reader :statsd

    def initialize(statsd)
      @statsd = statsd
    end

    def metric_name(old_name)
      PREFIX + old_name
    end

    def increment(name, opts = {})
      @statsd.increment(metric_name(name), opts)
    end

    def timing(name, value, opts = {})
      @statsd.timing(metric_name(name), value, opts)
    end

    # Additional StatsD like functions when needed.

    def time(name, opts = {}, &block)
      @statsd.time(metric_name(name), opts, &block)
    end

    # def decrement(name, opts = {})
    #   @statsd.decrement(metric_name(name), opts)
    # end

    # def gauge(name, value, opts = {})
    #   @statsd.gauge(metric_name(name), value, opts)
    # end

    # def count(name, value, opts = {})
    #   @statsd.count(metric_name(name), value, opts)
    # end

    # def histogram(name, value, opts = {})
    #   @statsd.histogram(metric_name(name), value, opts)
    # end

    # def set(name, value, opts = {})
    #   @statsd.set(metric_name(name), value, opts)
    # end

    # def batch(&block)
    #   @statsd.batch(&block)
    # end
  end
end
