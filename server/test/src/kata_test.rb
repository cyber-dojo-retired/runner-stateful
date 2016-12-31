require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix; 'FB0D4'; end

  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: new_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D7B',
  'new_kata with an invalid kata_id raises' do
    assert_method_raises(:new_kata, invalid_kata_ids, 'invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '183',
  'new_kata with kata_id that already exists raises' do
    new_kata
    begin
      assert_method_raises(:new_kata, kata_id, 'exists')
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: old_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CED',
  'old_kata with invalid kata_id raises' do
    assert_method_raises(:old_kata, invalid_kata_ids, 'invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0A2',
  'old_kata with valid kata_id that does not exist raises' do
    assert_method_raises(:old_kata, kata_id, '!exists')
  end

  private

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

  def assert_method_raises(method, kata_ids, message)
    [*kata_ids].each do |kata_id|
      error = assert_raises(ArgumentError) {
        self.send(method, { kata_id:kata_id })
      }
      assert_equal 'kata_id:'+message, error.message
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_name; [ 'cyber', 'dojo', kata_id ].join('_'); end
  def space; ' '; end

end
