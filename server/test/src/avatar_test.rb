require_relative 'test_base'

class AvatarTest < TestBase

  def self.hex_prefix; '20A7A'; end

  def hex_setup
    @image_name = 'cyberdojofoundation/gcc_assert'
    new_kata
  end

  def hex_teardown
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # new_avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B20',
  'new_avatar with an invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      assert_new_avatar_raises_kata_id(invalid_kata_id, 'salmon')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7C4',
  'new_avatar with non-existant kata_id raises' do
    kata_id = '42CF187311'
    assert_new_avatar_raises_kata_id(kata_id, 'salmon')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '35D',
  'new_avatar with existing kata_id but invalid avatar_name raises' do
    invalid_avatar_names.each do |invalid_avatar_name|
      assert_new_avatar_raises_avatar_name(kata_id, invalid_avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '119',
  'new_avatar with existing kata_id but avatar_name that already exists raises' do
    new_avatar({ avatar_name:'salmon' })
    assert_new_avatar_raises_avatar_name(kata_id, 'salmon')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # old_avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '2A8',
  'old_avatar with invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      assert_old_avatar_raises_kata_id(invalid_kata_id, 'salmon')
    end
  end

  test 'E35',
  'old_avatar with non-existant kata_id raises' do
    kata_id = '92BB3FE5B6'
    assert_old_avatar_raises_kata_id(kata_id, 'salmon')
  end

  test 'E5D',
  'old_avatar with existing kata_id but invalid avatar_name raises' do
    invalid_avatar_names.each do |invalid_avatar_name|
      assert_old_avatar_raises_avatar_name(kata_id, invalid_avatar_name)
    end
  end

  test 'D6F',
  'old_avatar with existing kata_id but avatar_name that does not exist raises' do
    assert_old_avatar_raises_avatar_name(kata_id, 'salmon')
  end

  private

  def assert_new_avatar_raises_kata_id(kata_id, avatar_name)
    assert_raises_method_message(:new_avatar, 'kata_id', kata_id, avatar_name)
  end

  def assert_new_avatar_raises_avatar_name(kata_id, avatar_name)
    assert_raises_method_message(:new_avatar, 'avatar_name', kata_id, avatar_name)
  end

  def assert_old_avatar_raises_kata_id(kata_id, avatar_name)
    assert_raises_method_message(:old_avatar, 'kata_id', kata_id, avatar_name)
  end

  def assert_old_avatar_raises_avatar_name(kata_id, avatar_name)
    assert_raises_method_message(:old_avatar, 'avatar_name', kata_id, avatar_name)
  end

  def assert_raises_method_message(method, message, kata_id, avatar_name)
    error = assert_raises(ArgumentError) {
      self.send(method, {
            kata_id:kata_id,
        avatar_name:avatar_name
      })
    }
    assert error.message.start_with?(message), error.message
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
