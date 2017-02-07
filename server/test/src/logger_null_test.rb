require_relative 'test_base'
require_relative '../../src/logger_null'

class LoggerNullTest < TestBase

  def self.hex_prefix; 'FA2'; end

  test 'F87',
  'logged message is lost' do
    logger = LoggerNull.new(nil)
    logger << 'hello'
  end

end
