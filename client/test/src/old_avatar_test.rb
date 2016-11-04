require_relative './client_test_base'

class OldAvatarTest < ClientTestBase

  def self.hex_prefix; '33A'; end

  test '70F',
  'old_avatar with illegal volume name does not complete' do
    old_avatar('a', ':')
    assert_equal 'Fixnum', status.class.name
    refute_equal completed, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1ED',
  'old_avatar with legal name completes' do
    new_avatar(test_id, 'salmon')
    old_avatar(test_id, 'salmon')
    assert_equal completed, status
  end

end
