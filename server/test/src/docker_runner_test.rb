
require_relative './lib_test_base'
require_relative './mock_sheller'

class DockerRunnerTest < LibTestBase

  def self.hex(suffix)
    '9D930' + suffix
  end

  def external_setup
    ENV[env_name('shell')] = 'MockSheller'
  end

  def external_teardown
    shell.teardown if shell.class.name == 'MockSheller'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B71',
  'pulled?(image_name) is false when image_name has not yet been pulled' do
    image_name = 'cyberdojofoundation/gcc_assert'
    no_gcc_assert = [
      "REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE",
      "cyberdojofoundation/java_cucumber          latest              06aa46aad63d        6 weeks ago         881.7 MB",
      "cyberdojo/runner                           1.12.2              a531a83580c9        18 minutes ago      56.05 MB"
    ].join("\n")
    shell.mock_exec(['docker images'], no_gcc_assert, success)
    refute runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '94E',
  'pulled?(image) is true when image_name has already been pulled' do
    image_name = 'cyberdojofoundation/gcc_assert'
    has_gcc_assert = [
      "REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE",
      "cyberdojofoundation/java_cucumber          latest              06aa46aad63d        6 weeks ago         881.7 MB",
      "cyberdojo/runner                           1.12.2              a531a83580c9        18 minutes ago      56.05 MB",
      "#{image_name}                              latest              da213d286ec5        4 months ago        99.16 MB"
    ].join("\n")
    shell.mock_exec(['docker images'], has_gcc_assert, success)
    assert runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DA5',
  'pull(image_name) issues shell(docker pull) command' do
    image_name = 'cyberdojofoundation/gcc_assert'
    shell.mock_exec(["docker pull #{image_name}"], any, success)
    output, exit_status = runner.pull(image_name)
    assert_equal any, output
    assert_equal success, exit_status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # start
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'F2E',
  'start(kata_id,avatar_name) issues shell(docker create volume) command' do
    @kata_id = test_id
    @avatar_name = 'lion'
    shell.mock_exec(["docker volume create --name #{volume_name}"], any, success)
    output, exit_status = runner.start(@kata_id, @avatar_name)
    assert_equal any, output
    assert_equal success, exit_status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'start creates a docker-volume' do
    @kata_id = test_id
    @avatar_name = 'lion'
    live_shelling
    runner.start(@kata_id, @avatar_name)
    output, exit_status = exec('docker volume ls')
    assert_equal success, exit_status
    assert output.include? volume_name
    exec("docker volume rm #{volume_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BB3',
  'run with red traffic light' do
    @kata_id = test_id
    @avatar_name = 'lion'
    live_shelling
    runner.start(@kata_id, @avatar_name)

    changed_files = {
      'hiker.cpp' => read('hiker.cpp'),
      'hiker.hpp' => read('hiker.hpp'),
      'hiker.tests.cpp' => read('hiker.tests.cpp'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile' => read('makefile')
    }

    output = runner.run(
      image_name = 'cyberdojofoundation/gcc_assert',
      @kata_id,
      @avatar_name,
      max_seconds = 10,
      delete_filenames = [],
      changed_files)

    # This creates a container with the files in it.
    # If I docker exec into this container and run cyber-dojo.sh
    # I get output (fix g++ not being seen later)
    #    make: g++: Command not found
    #    make: *** [makefile:20: hiker.compiled_hpp] Error 127
    # This output is not being seen
    # All I get here is output=nil

    p output

  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include Externals

  def runner; DockerRunner.new(self); end

  def success; 0; end

  def space; ' '; end

  def volume_name; 'cyber_dojo_' + @kata_id + '_' + @avatar_name; end

  def any; 'sdsdsd'; end

  def live_shelling
    ENV[env_name('shell')] = 'ExternalSheller'
    ENV[env_name('log')] = 'SpyLogger'
  end

  def exec(command)
    output, exit_success = shell.exec(command)
    assert_success(output, exit_success)
    return [output, exit_success]
  end

  def assert_success(output, exit_status)
    fail "exited(#{exit_status}):#{output}:" unless exit_status == success
  end

  def read(filename)
    IO.read("/app/test/src/start_files/#{filename}")
  end

end
