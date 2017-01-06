require_relative 'test_base'

class CustomAssertTest < TestBase

  def self.hex_prefix; '7D428'; end

  def hex_setup
    set_image_name image_for_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '249',
  '[Alpine] bad assert_exec raises' do
    @log = SpyLogger.new(self)
    error = assert_raises { assert_exec 'xxxx' }
    assert_equal 'No such file or directory - xxxx', error.message
    assert_equal [
      line,
      'COMMAND:xxxx',
      'RAISED-CLASS:Errno::ENOENT',
      'RAISED-TO_S:No such file or directory - xxxx'
    ], @log.spied
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '434',
  '[Alpine] bad assert_docker_exec raises' do
    error = assert_raises { assert_docker_exec 'xxxx' }
    expected = "docker exec cyber_dojo_7D42843400 sh -c 'xxxx'"
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def line
    '-' * 40
  end

end