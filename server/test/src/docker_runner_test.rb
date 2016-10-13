
require_relative './lib_test_base'
require_relative './mock_sheller'

class DockerRunnerTest < LibTestBase

  def self.hex(suffix)
    '9D9' + suffix
  end

  def setup
    super
    ENV[env_name('shell')]  = 'MockSheller'
  end

  def teardown
    shell.teardown
    super
  end

  test 'B71',
  'pulled?(image_name) is false when image_name has not yet been pulled' do
    image_name = 'cyberdojofoundation/gcc_assert'
    command = [ sudo, 'docker', 'images' ].join(space)
    output = [
      "REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE",
      "cyberdojofoundation/java_cucumber          latest              06aa46aad63d        6 weeks ago         881.7 MB",
      "cyberdojo/runner                           1.12.1              a531a83580c9        18 minutes ago      56.05 MB"
    ].join("\n")
    shell.mock_exec([command], output, success)
    refute runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '94E',
  'pulled?(image) is true when image_name has already been pulled' do
    image_name = 'cyberdojofoundation/gcc_assert'
    command = [ sudo, 'docker', 'images' ].join(space)
    output = [
      "REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE",
      "cyberdojofoundation/java_cucumber          latest              06aa46aad63d        6 weeks ago         881.7 MB",
      "cyberdojo/runner                           1.12.1              a531a83580c9        18 minutes ago      56.05 MB",
      "cyberdojofoundation/gcc_assert             latest              da213d286ec5        4 months ago        99.16 MB"
    ].join("\n")
    shell.mock_exec([command], output, success)
    assert runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include Externals

  def runner
    DockerRunner.new(self)
  end

  def success
    0
  end

  def sudo
    'sudo -u docker-runner sudo'
  end

  def space
    ' '
  end

end
