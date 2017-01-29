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
  # negative test cases: new_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '183',
  'new_kata with kata_id that already exists raises' do
    new_kata
    begin
      error = assert_raises(ArgumentError) { new_kata }
      assert_equal 'kata_id:exists', error.message
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: old_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0A2',
  'old_kata with valid kata_id that does not exist raises' do
    error = assert_raises(ArgumentError) { old_kata }
    assert_equal 'kata_id:!exists', error.message
  end

end
