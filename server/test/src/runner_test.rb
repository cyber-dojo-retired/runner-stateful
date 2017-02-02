require_relative 'test_base'

class RunnerTest < TestBase

  def self.hex_prefix; '4C8DB'; end

  test 'D01',
  'runner with valid_kata is does not raise' do
    new_runner(image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - -

  test '6FD',
  'runner with invalid kata_id raises' do
    invalid_kata_ids.each do |invalid_kata_id|
      error = assert_raises(ArgumentError) {
        new_runner(image_name, invalid_kata_id)
      }
      assert_equal 'kata_id:invalid', error.message
    end
  end

  private

  def invalid_kata_ids
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

end
