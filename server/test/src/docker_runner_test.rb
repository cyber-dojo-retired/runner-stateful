
require_relative './lib_test_base'
require_relative './mock_sheller'

class DockerRunnerTest < LibTestBase

  def self.hex
    '9D930'
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
  'run gcc:assert with failing test outputs assert diagnostic' do
    @kata_id = test_id
    hiker_c = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 9; }'
    ].join("\n")
    expected = [
      "Assertion failed: answer() == 42 (hiker.tests.c: life_the_universe_and_everything: 7)",
      "make: *** [makefile:14: test.output] Aborted"
    ].join("\n") + "\n"
    actual = runner_run(hiker_c)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  'run gcc:assert with passing test outputs all-tests-passed key-string' do
    @kata_id = test_id
    hiker_c = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 7; }'
    ].join("\n")
    expected = "All tests passed\n"
    actual = runner_run(hiker_c)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '13D',
  'run gcc:assert with syntax error outputs gcc diagnostic' do
    @kata_id = test_id
    hiker_c = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 9sss; }'
    ].join("\n")
    expected = [
      "hiker.c: In function 'answer':",
      "hiker.c:2:31: error: invalid suffix \"sss\" on integer constant",
      " int answer(void) { return 6 * 9sss; }",
      "                               ^",
      "hiker.c:2:1: error: control reaches end of non-void function [-Werror=return-type]",
      " int answer(void) { return 6 * 9sss; }",
      " ^",
      "cc1: all warnings being treated as errors",
      "make: *** [makefile:17: test] Error 1"
    ].join("\n") + "\n"
    actual = runner_run(hiker_c)
    assert_equal expected, actual
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

  def runner_run(hiker_c)
    @avatar_name = 'lion'
    live_shelling
    runner.start(@kata_id, @avatar_name)
    changed_files = {
      'hiker.c' => hiker_c,
      'hiker.h' => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
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
    exec("docker volume rm #{volume_name}")
    output
  end

end
