require_relative './client_test_base'

class NewAvatarTest < ClientTestBase

  def self.hex_prefix; '4F7'; end

  test 'C43',
  'new_avatar with illegal volume name is error' do
    new_avatar('a', ':')
    assert_equal 'error', status
  end

end
