require_relative 'test_base'
require_relative 'mock_sheller'

class KataTest < TestBase

  def self.hex_prefix; 'FB0D4'; end

  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; end

  test 'D7B',
  'new_kata with an invalid kata_id raises' do
    invalid_ids.each do |invalid_id|
      assert_raises_kata_id(invalid_id)
    end
  end

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
    invalid_ids.each do |invalid_id|
      assert_raises_kata_id(invalid_id)
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

  def invalid_ids
    [
      nil,          # not string
      Object.new,   # not string
      [],           # not string
      '',           # not 10 chars
      '123456789',  # not 10 chars
      '123456789AB',# not 10 chars
      '123456789G'  # not 10 hex-chars
    ]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

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

end
