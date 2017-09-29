require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix
    'FB0D4'
  end

  def hex_setup
    set_image_name "#{cdf}/gcc_assert"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'before kata_new kata does not exist,',
  'after kata_new it does exist,',
  'after kata_old it does not exist' do
    refute kata_exists?
    in_kata { assert kata_exists? }
    refute kata_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: kata_new
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '183',
  'kata_new with kata_id that already exists raises' do
    in_kata {
      error = assert_raises(ArgumentError) { kata_new }
      assert_equal 'kata_id:exists', error.message
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: kata_old
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0A2',
  'kata_old with valid kata_id that does not exist raises' do
    error = assert_raises(ArgumentError) { kata_old }
    assert_equal 'kata_id:!exists', error.message
  end

end
