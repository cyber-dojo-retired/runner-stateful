require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix; 'D2E7E'; end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C7A',
  'new_kata/old_kata' do
    refute kata_exists?
    new_kata
    assert kata_exists?
    old_kata
    refute kata_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: new_kata
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '2F2',
  'new_kata with invalid kata_id raises' do
    error = assert_raises { new_kata({ kata_id:Object.new }) }
    assert_equal 'RunnerService:new_kata:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '590',
  'new_kata with kata_id that already exists raises' do
    new_kata
    begin
      error = assert_raises { new_kata }
      assert_equal 'RunnerService:new_kata:kata_id:exists', error.message
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: old_kata
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BA3',
  'old_kata with invalid kata_id raises' do
    error = assert_raises { old_kata({ kata_id:Object.new }) }
    assert_equal 'RunnerService:old_kata:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '0B7',
  'old_kata with kata_id that does not exist raises' do
    error = assert_raises { old_kata }
    assert_equal 'RunnerService:old_kata:kata_id:!exists', error.message
  end

end
