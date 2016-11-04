require_relative './client_test_base'

class OldAvatarTest < ClientTestBase

  def self.hex_prefix; '33A'; end

  test '70F',
  'old_avatar with illegal volume name does not succeed' do
    old_avatar('a', ':')
    assert_equal 'Fixnum', status.class.name
    refute_success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1ED',
  'old_avatar with legal name succeeds' do
    new_avatar(test_id, 'salmon')
    old_avatar(test_id, 'salmon')
    assert_success
  end

end
