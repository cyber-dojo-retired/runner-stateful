require_relative 'test_base'

class AvatarTest < TestBase

  def self.hex_prefix
    '4F725'
  end

  def hex_setup
    kata_new
  end

  def hex_teardown
    kata_old
  end

  test 'D08',
  %w( avatar_exists ) do
    refute avatar_exists?
    avatar_new
    assert avatar_exists?
    avatar_old
    refute avatar_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: avatar_new
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E06',
  'avatar_new with invalid image_name raises' do
    error = assert_raises { avatar_new({ image_name:Object.new }) }
    assert_equal 'RunnerService:avatar_new:image_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '48A',
  'avatar_new with invalid kata_id raises' do
    error = assert_raises { avatar_new({ kata_id:Object.new }) }
    assert_equal 'RunnerService:avatar_new:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C43',
  'avatar_new with kata_id that does not exist name raises' do
    error = assert_raises { avatar_new({ kata_id:'6E070B323A' }) }
    assert_equal 'RunnerService:avatar_new:kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '1E0',
  'avatar_new with kata_id that exists and avatar_name that exists raises' do
    avatar_new
    begin
      error = assert_raises { avatar_new }
      assert_equal 'RunnerService:avatar_new:avatar_name:exists', error.message
    ensure
      avatar_old
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: avatar_old
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '538',
  'avatar_old with invalid image_name raises' do
    error = assert_raises { avatar_old({ image_name:Object.new }) }
    assert_equal 'RunnerService:avatar_old:image_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '70F',
  'avatar_old with invalid kata_id raises' do
    error = assert_raises { avatar_old({ kata_id:Object.new }) }
    assert_equal 'RunnerService:avatar_old:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '45E',
  'avatar_old with kata_id that does not exist raises' do
    error = assert_raises { avatar_old({ kata_id:'B8D2EA7DF1' }) }
    assert_equal 'RunnerService:avatar_old:kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DE2',
  'avatar_old with kata_id that exists and avatar_name that does not exist raises' do
    error = assert_raises { avatar_old }
    assert_equal 'RunnerService:avatar_old:avatar_name:!exists', error.message
  end

end
