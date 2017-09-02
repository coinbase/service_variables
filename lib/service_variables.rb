# frozen_string_literal: true

require 'redis'

# Module to create service level variables stored in Redis.
module ServiceVariables
  class NotConfiguredError < StandardError; end
  class InvalidValueError < StandardError; end

  DEFAULT_REDIS_KEY = 'service_variables_redis_key'
  BOOLEAN_VALUES = [true, false, 'true', 'false'].freeze

  attr_writer :service_variables_redis_client, :redis_key

  def configure(redis_client:, redis_key: nil)
    @service_variables_redis_client = redis_client
    @redis_key = redis_key
  end

  def boolean_option(name, default: nil)
    getter_method_name = "#{name}?".to_sym
    setter_method_name = "#{name}=".to_sym

    define_singleton_method getter_method_name do
      # Note that all values are stored in Redis as strings.
      value = get(name)
      value.nil? ? default : get(name) == 'true'
    end

    # Allow for `name` and `name?` accessors of boolean options.
    singleton_class.send(:alias_method, name, getter_method_name)

    define_singleton_method setter_method_name do |value|
      raise InvalidValueError, "Value isn't `true` or `false`" unless BOOLEAN_VALUES.include?(value)
      set(name, value.to_s)
    end
  end

  def integer_option(name, default: nil, min: nil, max: nil)
    define_singleton_method name do
      get(name)&.to_i || default
    end

    define_singleton_method "#{name}=" do |value|
      value = Integer(value) # raises ArgumentError if non integer value
      raise InvalidValueError, "Value too small. min = #{min.to_i}" if min && min > value
      raise InvalidValueError, "Value too large. max = #{max.to_i}" if max && max < value
      set(name, value&.to_s)
    end
  end

  def float_option(name, default: nil, min: nil, max: nil)
    define_singleton_method name do
      get(name)&.to_f || default
    end

    define_singleton_method "#{name}=" do |value|
      value = Float(value) # raises ArgumentError if non float value
      raise InvalidValueError, "Value too small. min = #{min.to_f}" if min && min > value
      raise InvalidValueError, "Value too large. max = #{max.to_f}" if max && max < value
      set(name, value&.to_s)
    end
  end

  def string_option(name, default: nil, enum: nil)
    define_singleton_method name do
      get(name) || default
    end

    define_singleton_method "#{name}=" do |value|
      raise InvalidValueError, "Only #{enum} values are allowed." if enum && !enum.include?(value)
      set(name, value)
    end
  end

  private

  def get(key)
    redis.hget(redis_hash_key, key)
  end

  def set(key, value)
    if value.nil?
      redis.hdel(redis_hash_key, key)
    else
      redis.hset(redis_hash_key, key, value)
    end
  end

  def redis
    return @service_variables_redis_client if @service_variables_redis_client.is_a?(Redis)
    raise NotConfiguredError, 'Redis client not given.'
  end

  def redis_hash_key
    @redis_key.nil? ? DEFAULT_REDIS_KEY : "#{DEFAULT_REDIS_KEY}:#{@redis_key}"
  end
end
