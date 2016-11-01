require_relative './client_test_base'

class OldAvatarTest < ClientTestBase

  def self.hex_prefix; '33A'; end

  test '70F',
  'old_avatar with illegal volume name is error' do
    old_avatar('a', ':')
    assert_equal 'error', status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1ED',
  'old_avatar with legal name succeeds' do
    new_avatar(test_id, 'salmon')
    old_avatar(test_id, 'salmon')
    assert_equal 0, status
  end

end
