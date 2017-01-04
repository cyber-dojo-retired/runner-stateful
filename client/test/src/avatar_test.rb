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
    refute avatar_exists?
    new_avatar
    assert avatar_exists?
    old_avatar
    refute avatar_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: new_avatar
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '48A',
  'new_avatar with invalid kata_id raises' do
    error = assert_raises { new_avatar({ kata_id:Object.new }) }
    assert_equal 'RunnerService:new_avatar:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C43',
  'new_avatar with kata_id that does not exist name raises' do
    error = assert_raises { new_avatar({ kata_id:'6E070B323A' }) }
    assert_equal 'RunnerService:new_avatar:kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1E0',
  'new_avatar with kata_id that exists and avatar_name that exists raises' do
    new_avatar
    begin
      error = assert_raises { new_avatar }
      assert_equal 'RunnerService:new_avatar:avatar_name:exists', error.message
    ensure
      old_avatar
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: old_avatar
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '70F',
  'old_avatar with invalid kata_id raises' do
    error = assert_raises { old_avatar({ kata_id:Object.new }) }
    assert_equal 'RunnerService:old_avatar:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '45E',
  'old_avatar with kata_id that does not exist raises' do
    error = assert_raises { old_avatar({ kata_id:'B8D2EA7DF1' }) }
    assert_equal 'RunnerService:old_avatar:kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DE2',
  'old_avatar with kata_id that exists and avatar_name that does not exist raises' do
    error = assert_raises { old_avatar }
    assert_equal 'RunnerService:old_avatar:avatar_name:!exists', error.message
  end

end
