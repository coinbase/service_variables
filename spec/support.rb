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
end

class CustomVars
  extend ServiceVariables

  configure redis_client: Redis.new(url: 'redis://0.0.0.0:6379'),
            redis_key: 'custom'

  integer_option :int, default: 1, min: 1, max: 10
end
