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
end
