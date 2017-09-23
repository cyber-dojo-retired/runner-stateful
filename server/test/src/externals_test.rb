require_relative 'test_base'

class ExternalsTest < TestBase

  include Externals

  def self.hex_prefix
    '7A9'
  end

  # - - - - - - - - - - - - - - - - -

  test '920',
  'default disk is DiskWriter' do
    assert_equal 'DiskWriter', disk.class.name
  end

  # - - - - - - - - - - - - - - - - -

  test '3EC',
  'default log is LoggerStdout' do
    assert_equal 'LoggerStdout', log.class.name
  end

  # - - - - - - - - - - - - - - - - -

  test '1B1',
  'default shell is ShellBasher' do
    assert_equal 'ShellBasher', shell.class.name
  end

end
