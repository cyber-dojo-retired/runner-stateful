require_relative './client_test_base'

class OldAvatarTest < ClientTestBase

  def self.hex_prefix; '33A'; end

  test '70F',
  'old_avatar with illegal volume name raises' do
    error = assert_raises { old_avatar('a', ':') }
    assert error.message.start_with? 'RunnerService:old_avatar'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1ED',
  'old_avatar with legal name succeeds' do
    new_avatar(image_name, test_id, 'salmon')
    old_avatar(test_id, 'salmon')
  end

end
