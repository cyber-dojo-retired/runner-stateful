require_relative 'test_base'
require_relative '../../src/null_logger'

class NullLoggerTest < TestBase

  def self.hex_prefix; 'FA2'; end

  test 'F87',
  'logged message is lost' do
    logger = NullLogger.new(nil)
    logger << 'hello'
  end

end
