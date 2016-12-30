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

  test 'B20',
  'new_avatar with an invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      assert_raises_kata_id(invalid_kata_id, 'salmon')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '35D',
  'new_avatar with invalid avatar_name raises' do
    invalid_avatar_names = [
      nil,
      Object.new,
      [],
      '',
      'scissors'
    ]
    invalid_avatar_names.each do |invalid_avatar_name|
      assert_raises_avatar_name(kata_id, invalid_avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '119',
  'new_avatar with avatar_name that already exists raises' do
    new_avatar({ avatar_name:'salmon' })
    assert_raises_avatar_name(kata_id, 'salmon')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_raises_kata_id(kata_id, avatar_name)
    error = assert_raises(ArgumentError) {
      new_avatar( { kata_id:kata_id })
    }
    assert error.message.start_with? 'kata_id'
  end

  def assert_raises_avatar_name(kata_id, avatar_name)
    error = assert_raises(ArgumentError) {
      new_avatar( {
            kata_id:kata_id,
        avatar_name:avatar_name
      })
    }
    assert error.message.start_with? 'avatar_name'
  end


=begin
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '183',
  'new_kata with kata_id that already exists raises' do
    new_kata
    begin
      assert_raises_kata_id(kata_id)
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CED',
  'old_kata with invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      assert_raises_kata_id(invalid_kata_id)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0A2',
  'old_kata with valid kata_id that does not exist raises' do
    error = assert_raises { old_kata }
    assert error.message.start_with? 'kata_id'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'before new_kata volume does not exist,',
  'after new_kata it does,',
  'after old_kata it does not' do
    refute volume_exists?
    new_kata
    assert volume_exists?
    old_kata
    refute volume_exists?
  end

  private

  def assert_raises_kata_id(id)
    error = assert_raises(ArgumentError) {
      new_kata( { kata_id:id })
    }
    assert error.message.start_with? 'kata_id'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_exists?
    cmd = [
      'docker volume ls',
      '--quiet',
      "--filter 'name=#{volume_name}'"
    ].join(space)
    stdout,_ = assert_exec(cmd)
    stdout.strip == volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_name; [ 'cyber', 'dojo', kata_id ].join('_'); end
  def space; ' '; end
=end

end
