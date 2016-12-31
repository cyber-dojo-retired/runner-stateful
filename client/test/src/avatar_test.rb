require_relative 'test_base'

class AvatarTest < TestBase

  def self.hex_prefix; '4F725'; end
  def hex_setup; new_kata; end
  def hex_teardown; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '26D',
  'new_avatar/old_avatar' do
    new_avatar
    old_avatar
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '48A',
  'new_avatar with invalid kata_id raises' do
    error = assert_raises {
      new_avatar(image_name, Object.new, 'salmon')
    }
    assert_equal 'RunnerService:new_avatar:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C43',
  'new_avatar with kata_id that does not exist name raises' do
    error = assert_raises {
      new_avatar(image_name, kata_id.reverse, 'salmon')
    }
    assert_equal 'RunnerService:new_avatar:kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '70F',
  'old_avatar with invalid kata_id raises' do
    error = assert_raises {
      old_avatar(image_name, Object.new, 'salmon')
    }
    assert_equal 'RunnerService:old_avatar:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '45E',
  'old_avatar with kata_id that does not exist raises' do
    error = assert_raises {
      old_avatar(image_name, kata_id.reverse, 'salmon')
    }
    assert_equal 'RunnerService:old_avatar:kata_id:!exists', error.message
  end

end
