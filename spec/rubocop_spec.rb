# frozen_string_literal: true

require 'open3'

RUBOCOP_COMMAND = 'bundle exec rubocop --color'

describe 'rubocop' do
  it 'should ensure that we have linted code' do
    stdout, stderr, exit_status = Open3.capture3(RUBOCOP_COMMAND)
    expect(exit_status.success?).to eq(true), "#{stdout}\n#{stderr}"
  end
end
