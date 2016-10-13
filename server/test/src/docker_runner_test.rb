
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B71',
  'pulled?(image_name) is false when image_name has not yet been pulled' do
    image_name = 'cyberdojofoundation/gcc_assert'
    command = [ sudo, 'docker', 'images' ].join(space)
    no_gcc_assert = [
      "REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE",
      "cyberdojofoundation/java_cucumber          latest              06aa46aad63d        6 weeks ago         881.7 MB",
      "cyberdojo/runner                           1.12.1              a531a83580c9        18 minutes ago      56.05 MB"
    ].join("\n")
    shell.mock_exec([command], no_gcc_assert, success)
    refute runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '94E',
  'pulled?(image) is true when image_name has already been pulled' do
    image_name = 'cyberdojofoundation/gcc_assert'
    command = [ sudo, 'docker', 'images' ].join(space)
    has_gcc_assert = [
      "REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE",
      "cyberdojofoundation/java_cucumber          latest              06aa46aad63d        6 weeks ago         881.7 MB",
      "cyberdojo/runner                           1.12.1              a531a83580c9        18 minutes ago      56.05 MB",
      "cyberdojofoundation/gcc_assert             latest              da213d286ec5        4 months ago        99.16 MB"
    ].join("\n")
    shell.mock_exec([command], has_gcc_assert, success)
    assert runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DA5',
  'pull(image_name) issues shell(docker pull) command' do
    image_name = 'cyberdojofoundation/gcc_assert'
    command = [ sudo, 'docker', 'pull', image_name ].join(space)
    info = 'sdsdsd'
    shell.mock_exec([command], info, success)
    output, exit_status = runner.pull(image_name)
    assert_equal info, output
    assert_equal exit_status, success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # start
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'F2E',
  'start(kata_id,avatar_name) issues shell(docker create volume) command' do
    kata_id = '77CC5D7F80'
    avatar_name = 'lion'
    volume_name =  [ 'cyber_dojo', kata_id, avatar_name ].join('_')
    command = [ sudo, 'docker', 'volume', 'create', volume_name ].join(space)
    info = 'sdsdsd'
    shell.mock_exec([command], info, success)
    output, exit_status = runner.start(kata_id, avatar_name)
    assert_equal info, output
    assert_equal exit_status, success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - -



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
