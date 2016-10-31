require_relative './client_test_base'

class OldAvatarTest < ClientTestBase

  def self.hex_prefix; '33A'; end

  test '70F',
  'old_avatar with illegal volume name is error' do
    old_avatar('a', ':')
    assert_equal 'error', status
  end

end
