require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix
    'D2E7E'
  end

  test 'D87',
  %w( kata_exists ) do
    refute kata_exists?
    kata_new
    assert kata_exists?
    kata_old
    refute kata_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: kata_new
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '4D7',
  'kata_new with invalid image_name raises' do
    error = assert_raises { kata_new({ image_name:Object.new }) }
    assert_equal 'RunnerService:kata_new:image_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '2F2',
  'kata_new with invalid kata_id raises' do
    error = assert_raises { kata_new({ kata_id:Object.new }) }
    assert_equal 'RunnerService:kata_new:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '590',
  'kata_new with kata_id that already exists raises' do
    kata_new
    begin
      error = assert_raises { kata_new }
      assert_equal 'RunnerService:kata_new:kata_id:exists', error.message
    ensure
      kata_old
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: kata_old
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A87',
  'kata_old with invalid image_name raises' do
    error = assert_raises { kata_old({ image_name:Object.new }) }
    assert_equal 'RunnerService:kata_old:image_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BA3',
  'kata_old with invalid kata_id raises' do
    error = assert_raises { kata_old({ kata_id:Object.new }) }
    assert_equal 'RunnerService:kata_old:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '0B7',
  'kata_old with kata_id that does not exist raises' do
    error = assert_raises { kata_old }
    assert_equal 'RunnerService:kata_old:kata_id:!exists', error.message
  end

end
