require_relative 'test_base'

class AvatarTest < TestBase

  def self.hex_prefix; '4F725'; end
  def hex_setup; new_kata; end
  def hex_teardown; old_kata; end

  test '26D',
  'new_avatar/old_avatar sunny-day scenario' do
    new_avatar
    old_avatar
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C43',
  'new_avatar with invalid kata_id name raises' do
    error = assert_raises {
      new_avatar(image_name, kata_id.reverse, 'salmon')
    }
    assert error.message.start_with? 'RunnerService:new_avatar'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '70F',
  'old_avatar with illegal volume name raises' do
    error = assert_raises { old_avatar('a', ':') }
    assert error.message.start_with? 'RunnerService:old_avatar'
  end

end
