
require_relative './lib_test_base'
require_relative './null_logger'

class DockerRunnerPullingTest < LibTestBase

  def self.hex
    'CFC'
  end

  def external_setup
    assert_equal 'ExternalSheller', shell.class.name
    ENV[env_name('log')] = 'NullLogger'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A71',
  'pulled?(image_name) is false when image_name has not yet been pulled' do
    refute runner.pulled?('thisdoes/not_exist')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A4E',
  'pulled?(image_name) is true when image_name has already been pulled' do
    # use image-name of runner itself
    assert runner.pulled?('cyberdojo/runner')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DA5',
  'after pull(image_name) pulled(image_name) is true' do
    # something small not used in cyber-dojo
    image_name = 'busybox'
    refute runner.pulled?(image_name)
    runner.pull(image_name)
    assert runner.pulled?(image_name)
    output, exit_status = shell.exec("docker rmi #{image_name}")
    fail "exited(#{exit_status}):#{output}:" unless exit_status == success
  end

  private

  include Externals

  def runner; DockerRunner.new(self); end

  def success; 0; end

end

