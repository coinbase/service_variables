# frozen_string_literal: true

require 'redis'

# Module to create service level variables stored in Redis.
module ServiceVariables
  class NotConfiguredError < StandardError; end
  class InvalidValueError < StandardError; end

  DEFAULT_REDIS_KEY = 'service_variables_redis_key'
  BOOLEAN_VALUES = [true, false, 'true', 'false'].freeze
  FAILURE_MODES = %i[raise_exception use_default use_last_value].freeze

  attr_writer :service_variables_redis_client, :redis_key

  def configure(redis_client:, redis_key: nil, failure_mode: :raise_exception)
    @service_variables_redis_client = redis_client
    @redis_key = redis_key

    raise InvalidValueError unless FAILURE_MODES.include?(failure_mode)
    @failure_mode = failure_mode
    @last_value_map = {}
  end

  def boolean_option(name, default: nil, failure_mode: @failure_mode)
    getter_method_name = "#{name}?".to_sym
    setter_method_name = "#{name}=".to_sym

    define_singleton_method getter_method_name do
      # Note that all values are stored in Redis as strings.
      value = get(name, failure_mode)
      value.nil? ? default : get(name, failure_mode) == 'true'
    end

    # Allow for `name` and `name?` accessors of boolean options.
    singleton_class.send(:alias_method, name, getter_method_name)

    define_singleton_method setter_method_name do |value|
      raise InvalidValueError, "Value isn't `true` or `false`" unless BOOLEAN_VALUES.include?(value)
      set(name, value.to_s)
    end
  end

  def integer_option(name, default: nil, min: nil, max: nil, failure_mode: @failure_mode)
    define_singleton_method name do
      get(name, failure_mode)&.to_i || default
    end

    define_singleton_method "#{name}=" do |value|
      value = Integer(value) # raises ArgumentError if non integer value
      raise InvalidValueError, "Value too small. min = #{min.to_i}" if min && min > value
      raise InvalidValueError, "Value too large. max = #{max.to_i}" if max && max < value
      set(name, value&.to_s)
    end
  end

  def float_option(name, default: nil, min: nil, max: nil, failure_mode: @failure_mode)
    define_singleton_method name do
      get(name, failure_mode)&.to_f || default
    end

    define_singleton_method "#{name}=" do |value|
      value = Float(value) # raises ArgumentError if non float value
      raise InvalidValueError, "Value too small. min = #{min.to_f}" if min && min > value
      raise InvalidValueError, "Value too large. max = #{max.to_f}" if max && max < value
      set(name, value&.to_s)
    end
  end

  def string_option(name, default: nil, enum: nil, failure_mode: @failure_mode)
    define_singleton_method name do
      get(name, failure_mode) || default
    end

    define_singleton_method "#{name}=" do |value|
      raise InvalidValueError, "Only #{enum} values are allowed." if enum && !enum.include?(value)
      set(name, value)
    end
  end

  private

  def get(key, failure_mode)
    redis.hget(redis_hash_key, key)
  rescue Redis::BaseConnectionError => e
    raise e if failure_mode == :raise_exception
    # If Redis returns a nil, then the default value is used, so we do the same with :use_default
    return nil if failure_mode == :use_default
    return @last_value_map[key] if failure_mode == :use_last_value
    raise InvalidValueError unless FAILURE_MODES.include?(failure_mode)
  end

  def set(key, value)
    if value.nil?
      redis.hdel(redis_hash_key, key)
    else
      redis.hset(redis_hash_key, key, value)
    end

    @last_value_map[key] = value
  end

  def redis
    return @service_variables_redis_client if @service_variables_redis_client.is_a?(Redis)
    raise NotConfiguredError, 'Redis client not given.'
  end

  def redis_hash_key
    @redis_key.nil? ? DEFAULT_REDIS_KEY : "#{DEFAULT_REDIS_KEY}:#{@redis_key}"
  end
end
