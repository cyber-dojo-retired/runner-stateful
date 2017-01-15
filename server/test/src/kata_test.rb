require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix; 'FB0D4'; end

  def hex_setup
    set_image_name 'cyberdojofoundation/gcc_assert'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'before new_kata kata does not exist,',
  'after new_kata it does exist,',
  'after old_kata it does not exist' do
    refute kata_exists?
    new_kata
    assert kata_exists?
    old_kata
    refute kata_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: kata_exists
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E9E',
  'kata_exists with an invalid kata_id raises' do
    assert_method_raises(:kata_exists?, invalid_kata_ids, 'invalid')
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

  def assert_method_raises(method, kata_ids, message)
    [*kata_ids].each do |kata_id|
      error = assert_raises(ArgumentError) {
        self.send(method, { kata_id:kata_id })
      }
      assert_equal 'kata_id:'+message, error.message
    end
  end

end
