require_relative 'runner_test_base'
require_relative 'spy_logger'

class SpyLoggerTest < RunnerTestBase

  def self.hex_prefix; 'CD4'; end

  test '20C',
  'logged message is spied' do
    logger = SpyLogger.new(nil)
    assert_equal [], logger.spied
    logger << 'hello'
    assert_equal ['hello'], logger.spied
    logger << 'world'
    assert_equal ['hello','world'], logger.spied
  end

end
