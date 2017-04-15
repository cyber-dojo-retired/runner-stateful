require_relative 'test_base'

class RunnerTest < TestBase

  def self.hex_prefix; '4C8DB'; end

  # - - - - - - - - - - - - - - - - -

  test 'D00', %w(
  direct call to runner.ctor with invalid image_name raises
  ) do
    error = assert_raises(ArgumentError) {
      SharedVolumeRunner.new(self, invalid_image_name='', kata_id)
    }
    assert_equal 'image_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - -

  test 'D01', %w(
  runner with valid image_name and valid kata_id does not raise
  ) do
    new_runner('cdf/gcc_assert', kata_id)
  end

  # - - - - - - - - - - - - - - - - -

  test 'D02', %w(
  default runner is SharedVolumeRunner
  ) do
    assert_runner_class 'cdf/gcc_assert', 'SharedVolumeRunner'
    assert_runner_class 'cdf/gcc_assert:1.2', 'SharedVolumeRunner'
    assert_runner_class 'quay.io:8080/cdf/gcc_assert:latest', 'SharedVolumeRunner'
    assert_runner_class 'localhost/cdf/gcc_assert:1.2', 'SharedVolumeRunner'
  end

  # - - - - - - - - - - - - - - - - -

  test 'D03', %w(
  runner for image_name ending in 'shared_disk' is SharedVolumeRunner
  ) do
    assert_runner_class 'cdf/gcc_assert_shared_disk', 'SharedVolumeRunner'
    assert_runner_class 'cdf/gcc_assert_shared_disk:1.2', 'SharedVolumeRunner'
    assert_runner_class 'quay.io:8080/cdf/gcc_assert_shared_disk:latest', 'SharedVolumeRunner'
    assert_runner_class 'localhost/cdf/gcc_assert_shared_disk:1.2', 'SharedVolumeRunner'
  end

=begin
  # These pass but I'm turning them off till to keep 100% coverage
  # till I start to use SharedContainerRunner

   test 'D04', %w(
   runner for image_name ending in 'shared_process' is SharedContainerRunner
   ) do
     expected = 'SharedContainerRunner'
     assert_runner_class 'cdf/gcc_assert_shared_process', expected
     assert_runner_class 'cdf/gcc_assert_shared_process:1.2', expected
     assert_runner_class 'quay.io:8080/cdf/gcc_assert_shared_process:latest', expected
     assert_runner_class 'localhost/cdf/gcc_assert_shared_process:1.2', expected
   end
=end

  # - - - - - - - - - - - - - - - - -

  test 'E2A', %w(
  runner with invalid image_name raises
  ) do
    invalid_image_names.each do |invalid_image_name|
      error = assert_raises(ArgumentError) {
        new_runner(invalid_image_name, kata_id)
      }
      assert_equal 'image_name:invalid', error.message
    end
  end

  # - - - - - - - - - - - - - - - - -

  test '6FD', %w(
  runner with invalid kata_id raises
  ) do
    invalid_kata_ids.each do |invalid_kata_id|
      error = assert_raises(ArgumentError) {
        new_runner('cdf/gcc_assert', invalid_kata_id)
      }
      assert_equal 'kata_id:invalid', error.message
    end
  end

  private

  def assert_runner_class(image_name, expected)
    assert_equal expected, new_runner(image_name, kata_id).class.name
  end

  def invalid_image_names
    [
      '',             # nothing!
      '_',            # cannot start with separator
      'name_',        # cannot end with separator
      'ALPHA/name',   # no uppercase
      'alpha/name_',  # cannot end in separator
      'alpha/_name',  # cannot begin with separator
    ]
  end

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
