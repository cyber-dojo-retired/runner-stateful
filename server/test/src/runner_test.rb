require_relative 'test_base'

class RunnerTest < TestBase

  def self.hex_prefix; '4C8DB'; end

  # - - - - - - - - - - - - - - - - -

  test 'A53',
  %w( runner with invalid image_name raises ) do
    invalid_image_names.each do |invalid_image_name|
      error = assert_raises(ArgumentError) {
        runner = SharedVolumeRunner.new(self, invalid_image_name, kata_id)
      }
      assert_equal 'image_name:invalid', error.message
    end
  end

  # - - - - - - - - - - - - - - - - -

  test '6FD',
  %w( runner with invalid kata_id raises ) do
    invalid_kata_ids.each do |invalid_kata_id|
      error = assert_raises(ArgumentError) {
        runner = SharedVolumeRunner.new(self, 'cdf/gcc_assert', invalid_kata_id)
      }
      assert_equal 'kata_id:invalid', error.message
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'D01',
  %w( runner with valid image_name and valid kata_id does not raise ) do
    SharedVolumeRunner.new(self, 'cdf/gcc_assert', kata_id)
  end

  # - - - - - - - - - - - - - - - - -

  private

  def invalid_image_names
    [
      '',             # nothing!
      '_',            # cannot start with separator
      'name_',        # cannot end with separator
      'ALPHA/name',   # no uppercase
      'alpha/name_',  # cannot end in separator
      'alpha/_name',  # cannot begin with separator
      'n:tag space',  # tags can't contain a space
      'n:-tag',       # tags can't start with a -
      'n:.tag',       # tags can't start with a .
    ]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
