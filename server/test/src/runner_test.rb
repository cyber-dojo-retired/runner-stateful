require_relative 'test_base'

class RunnerAlternative
  def initialize(_,_,_)
  end
end

class RunnerTest < TestBase

  def self.hex_prefix; '4C8DB'; end

  test '186',
  'runner can be set via CYBER_DOJO_RUNNER_CLASS environment-variable' do
    existing_runner = ENV['CYBER_DOJO_RUNNER_CLASS']
    ENV['CYBER_DOJO_RUNNER_CLASS'] = 'RunnerAlternative'
    begin
      assert_equal 'RunnerAlternative', runner.class.name
    ensure
      ENV['CYBER_DOJO_RUNNER_CLASS'] = existing_runner
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'C18',
  'runner defaults to DockerKataVolumeRunner if not set via',
  'CYBER_DOJO_RUNNER_CLASS environment-variable' do
    existing_runner = ENV['CYBER_DOJO_RUNNER_CLASS']
    ENV.delete('CYBER_DOJO_RUNNER_CLASS')
    begin
      assert_equal 'DockerKataVolumeRunner', runner.class.name
    ensure
      ENV['CYBER_DOJO_RUNNER_CLASS'] = existing_runner
    end
  end

  # - - - - - - - - - - - - - - - - -

  test 'D01',
  'runner with valid image_name and valid kata_id does not raise' do
    new_runner(image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - -

  test 'E2A',
  'runner with invalid image_name raises' do
    invalid_image_names.each do |invalid_image_name|
      error = assert_raises(ArgumentError) {
        new_runner(invalid_image_name, kata_id)
      }
      assert_equal 'image_name:invalid', error.message
    end
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

  def image_name
    'cyberdojofoundation/gcc_assert'
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
