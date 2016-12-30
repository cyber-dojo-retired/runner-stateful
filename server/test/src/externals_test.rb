require_relative 'test_base'

class ExternalsTest < TestBase

  include Externals

  def self.hex_prefix; '7A9'; end

  # - - - - - - - - - - - - - - - - -

  test '920',
  'default disk is DiskWriter' do
    assert_equal 'DiskWriter', disk.class.name
  end

  # - - - - - - - - - - - - - - - - -

  test '3EC',
  'default log is StdoutLogger' do
    assert_equal 'StdoutLogger', log.class.name
  end

  # - - - - - - - - - - - - - - - - -

  test '1B1',
  'default shell is Sheller' do
    assert_equal 'Sheller', shell.class.name
  end

end
