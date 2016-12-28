require_relative 'client_test_base'

class NewAvatarTest < ClientTestBase

  def self.hex_prefix; '4F725'; end

  test 'C43',
  'new_avatar with illegal volume name raises' do
    error = assert_raises { new_avatar(image_name, 'a', ':') }
    assert error.message.start_with? 'RunnerService:new_avatar'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '26D',
  'new_avatar with legal name succeeds' do
    begin
      new_avatar(image_name, test_id, 'salmon')
    ensure
      old_avatar(test_id, 'salmon')
    end
  end

end
