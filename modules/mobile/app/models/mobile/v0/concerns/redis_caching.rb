# frozen_string_literal: true

module Mobile
  module V0
    module Concerns
      module RedisCaching
        extend ActiveSupport::Concern

        class_methods do
          def redis_config(config)
            @redis_namespace = config[:namespace]
            @redis_ttl = config[:each_ttl]
            @redis = Redis::Namespace.new(@redis_namespace, redis: Redis.current)
          end

          def get_cached(key)
            result = @redis.get(key)
            return nil unless result

            data = JSON.parse(result)
            data.map { |i| new(i.deep_symbolize_keys) }
          end

          def set_cached(key, data)
            @redis.set(key, data.to_json)
            @redis.expire(key, @redis_ttl)
          end

          def clear_cache(key)
            @redis.del(key)
          end
        end
      end
    end
  end
end
