require_relative 'test_base'

class AvatarTest < TestBase

  def self.hex_prefix
    '20A7A'
  end

  def hex_setup
    set_image_name 'cyberdojofoundation/gcc_assert'
    kata_new
  end

  def hex_teardown
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '75E', %w(
  before avatar_new avatar does not exist
  after avatar_new it does exist
  ) do
    refute avatar_exists?
    avatar_new
    assert avatar_exists?
    avatar_old
    refute avatar_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9BD', %w( [Alpine]
  in a pristine Alpine image there is an existing user called squid
  (who knew eh) which clashes with the squid avatar and has to be handled
  somehow, either by an explicit runtime work-around (what it did at first)
  or by replacing the user in the built docker image (what it does now)
  ) do
    refute avatar_exists?('squid')
    avatar_new('squid')
    assert avatar_exists?('squid')
    avatar_old('squid')
    refute avatar_exists?('squid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A64', %w(
  avatar resurrection requires
  avatar_new() has to work after avatar_old()
  ) do
    avatar_new
    avatar_old
    avatar_new
    avatar_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative tests cases: avatar_new
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7C4', %w(
  avatar_new with non-existent kata_id raises
  ) do
    error = assert_raises(ArgumentError) {
      kata_id = '92BB3FE5B6'
      runner = Runner.new(self, image_name, kata_id)
      runner.avatar_new('salmon', {})
    }
    assert_equal 'kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '35D', %w(
  avatar_new with existing kata_id
    but invalid avatar_name raises
  ) do
    assert_method_raises(
      :avatar_new,
      kata_id,
      invalid_avatar_names,
      'avatar_name:invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '119', %w(
  avatar_new with existing kata_id
    but avatar_name that already exists raises
  ) do
    avatar_new
    begin
      error = assert_raises(ArgumentError) { avatar_new }
      assert_equal 'avatar_name:exists', error.message
    ensure
      avatar_old
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: avatar_old
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E35', %w(
  avatar_old with non-existent kata_id raises
  ) do
    error = assert_raises(ArgumentError) {
      kata_id = '92BB3FE5B6'
      runner = Runner.new(self, image_name, kata_id)
      runner.avatar_old('salmon')
    }
    assert_equal 'kata_id:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E5D', %w(
  avatar_old with existing kata_id
    but invalid avatar_name raises
  ) do
    assert_method_raises(
      :avatar_old,
      kata_id,
      invalid_avatar_names,
      'avatar_name:invalid')
  end

  test 'D6F', %w(
  avatar_old with existing kata_id
    but avatar_name that does not exist raises
  ) do
    error = assert_raises(ArgumentError) { avatar_old('salmon') }
    assert_equal 'avatar_name:!exists', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test case: user_id
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A10', %w(
  user_id with invalid avatar_name raises
  ) do
    invalid_avatar_names.each do |invalid_avatar_name|
      error = assert_raises(ArgumentError) {
        runner.user_id(invalid_avatar_name)
      }
      assert_equal 'avatar_name:invalid', error.message
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test case: user_id
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0C8', %w(
  sandbox_path with invalid avatar_name raises
  ) do
    invalid_avatar_names.each do |invalid_avatar_name|
      error = assert_raises(ArgumentError) {
        runner.avatar_dir(invalid_avatar_name)
      }
      assert_equal 'avatar_name:invalid', error.message
    end
  end


  private

  def assert_method_raises(method, kata_ids, avatar_names, message)
    [*kata_ids].each do |kata_id|
      [*avatar_names].each do |avatar_name|
        error = assert_raises(ArgumentError) {
          self.send(method, {
                kata_id:kata_id,
            avatar_name:avatar_name
          })
        }
      assert_equal message, error.message
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def invalid_avatar_names
    [
      nil,
      Object.new,
      [],
      '',
      'scissors'
    ]
  end

end
