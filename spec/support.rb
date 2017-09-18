# frozen_string_literal: true

require 'service_variables'

class NotConfigured
  extend ServiceVariables

  boolean_option :bar
end

class Vars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379')

  boolean_option :bool, default: true
  integer_option :int, default: 5, min: 1, max: 10
  float_option :float, default: 3.9, min: 1.2, max: 9.3
  string_option :string, default: 'string 0', enum: ['string 0', 'string 1']
  string_option :string2, default: 'string'
end

class CustomVars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379'),
            redis_key: 'custom'

  integer_option :int, default: 1, min: 1, max: 10
end

class RaiseExceptionVars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379')

  integer_option :int, default: 1, min: 1, max: 10
end

class DefaultFailureVars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379'), failure_mode: :use_default

  integer_option :int, default: 1, min: 1, max: 10
end

class LastValueFailureVars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379'), failure_mode: :use_last_value

  integer_option :int, default: 1, min: 1, max: 10
end

class MixedFailureVars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379'), failure_mode: :use_default

  integer_option :int, default: 1, min: 1, max: 10, failure_mode: :use_last_value
  string_option :string, default: 'string 0', enum: ['string 0', 'string 1'],
                         failure_mode: :raise_exception
  boolean_option :bool, default: true
end

class InvalidFailureVars
  extend ServiceVariables
end
