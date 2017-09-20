# frozen_string_literal: true

require 'service_variables'
require 'redis'
require 'rspec'
require_relative 'support.rb'

describe ServiceVariables do
  before do
    # clear all Redis values before each test
    Redis.new(url: 'redis://0.0.0.0:6379').flushall
  end

  describe 'using without configuration' do
    it 'should raise an exception to inform the developer' do
      expect { NotConfigured.bar }.to raise_error(
        ServiceVariables::NotConfiguredError, 'Redis client not given.'
      )
    end
  end

  # Test data inspired from real Kibana URLs set up through their UI.
  describe 'configured object' do
    it 'should return expected default values' do
      expect(Vars.bool).to eq(true)
      expect(Vars.int).to eq(5)
      expect(Vars.float).to eq(3.9)
      expect(Vars.string).to eq('string 0')
    end

    it 'should allow for updating values within bounds' do
      expect { Vars.bool = false }.to change { Vars.bool }.from(true).to(false)
      expect { Vars.int = 2 }.to change { Vars.int }.from(5).to(2)
      expect { Vars.float = 2.1 }.to change { Vars.float }.from(3.9).to(2.1)
      expect { Vars.string = 'string 1' }.to change { Vars.string }.from('string 0').to('string 1')
      expect { Vars.string2 = 'any' }.to change { Vars.string2 }.from('string').to('any')
    end

    it 'should raise when updating values out of bounds' do
      expect { Vars.int = 0 }.to raise_error(
        ServiceVariables::InvalidValueError, 'Value too small. min = 1'
      )
      expect { Vars.int = 11 }.to raise_error(
        ServiceVariables::InvalidValueError, 'Value too large. max = 10'
      )
      expect { Vars.float = 1.1 }.to raise_error(
        ServiceVariables::InvalidValueError, 'Value too small. min = 1.2'
      )
      expect { Vars.float = 9.4 }.to raise_error(
        ServiceVariables::InvalidValueError, 'Value too large. max = 9.3'
      )
      expect { Vars.string = 'string 2' }.to raise_error(
        ServiceVariables::InvalidValueError, 'Only ["string 0", "string 1"] values are allowed.'
      )
    end
  end

  describe 'multiple configuration options' do
    it 'should allow for separation by redis key' do
      Vars.int = 8
      CustomVars.int = 9
      expect(Vars.int).to eq(8)
      expect(CustomVars.int).to eq(9)
    end
  end

  describe 'raise_exception default configuration for failures' do
    it 'should raise an exception if redis cannot connect' do
      expect(RaiseExceptionVars.int).to eq(1)
      RaiseExceptionVars.int = 5
      expect(RaiseExceptionVars.int).to eq(5)
      allow_any_instance_of(Redis).to receive(:hget).and_raise(Redis::BaseConnectionError)
      expect { RaiseExceptionVars.int }.to raise_error(
        Redis::BaseConnectionError
      )
    end
  end

  describe 'use_default configuration for failures' do
    it 'should use the default value if redis cannot connect' do
      expect(DefaultFailureVars.int).to eq(1)
      DefaultFailureVars.int = 5
      expect(DefaultFailureVars.int).to eq(5)
      allow_any_instance_of(Redis).to receive(:hget).and_raise(Redis::BaseConnectionError)
      expect(DefaultFailureVars.int).to eq(1)
    end
  end

  describe 'use_last_value configuration for failures' do
    it 'should return the last value if redis cannot connect' do
      expect(LastValueFailureVars.int).to eq(1)
      LastValueFailureVars.int = 5
      expect(LastValueFailureVars.int).to eq(5)
      allow_any_instance_of(Redis).to receive(:hget).and_raise(Redis::BaseConnectionError)
      expect(LastValueFailureVars.int).to eq(5)
    end
  end

  describe 'multiple configuration for failures' do
    it 'should use variable specific failure modes to return values' do
      MixedFailureVars.int = 5
      expect(MixedFailureVars.int).to eq(5)

      MixedFailureVars.string = "string 1"
      expect(MixedFailureVars.string).to eq("string 1")

      MixedFailureVars.bool = false
      expect(MixedFailureVars.bool).to eq(false)

      allow_any_instance_of(Redis).to receive(:hget).and_raise(Redis::BaseConnectionError)

      expect(MixedFailureVars.int).to eq(5)
      expect { MixedFailureVars.string }.to raise_error(Redis::BaseConnectionError)
      expect(MixedFailureVars.bool).to eq(true)
    end
  end

  describe 'handle invalid failure mode configurations' do
    it 'should raise an error' do
      expect do
        InvalidFailureVars.configure(redis_client: Redis.new(url: 'redis://0.0.0.0:6379'),
                                     failure_mode: :bad_mode)
      end.to raise_error ServiceVariables::InvalidValueError
    end
  end
end
