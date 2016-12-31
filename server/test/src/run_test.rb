require_relative 'test_base'

class RunTest < TestBase

  def self.hex_prefix; '58410'; end

  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; end

  test 'D7B',
  'run with an invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      assert_raises_kata_id(invalid_kata_id)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1DC',
  'run with valid kata_id that does not exist raises' do
    kata_id = '0C67EC0416'
    assert_raises_kata_id(kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7FE',
  'run with kata_id that exists but invalid avatar_name raises' do
    new_kata
    begin
      assert_raises_avatar_name(kata_id, 'scissors')
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '951',
  'run with kata_id that exists and valid avatar_name that does not exist yet raises' do
    new_kata
    begin
      assert_raises_avatar_name(kata_id, 'salmon')
    ensure
      old_kata
    end
  end

  private

  def assert_raises_kata_id(kata_id)
    error = assert_raises(ArgumentError) {
      sss_run( { kata_id:kata_id })
    }
    assert error.message.start_with?('kata_id'), error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_raises_avatar_name(kata_id, avatar_name)
    error = assert_raises(ArgumentError) {
      sss_run( {
            kata_id:kata_id,
        avatar_name:avatar_name
      })
    }
    assert error.message.start_with?('avatar_name'), error.message
  end

end
