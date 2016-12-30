require_relative 'client_test_base'

class NewAvatarTest < ClientTestBase

  def self.hex_prefix; '4F725'; end
  def hex_setup; new_kata; end
  def hex_teardown; old_kata; end

  test 'C43',
  'new_avatar with invalid kata_id name raises' do
    error = assert_raises {
      new_avatar(image_name, kata_id.reverse, 'salmon')
    }
    assert error.message.start_with? 'RunnerService:new_avatar'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '26D',
  'new_avatar sunny-day scenario' do
    new_avatar
    old_avatar
  end

end
