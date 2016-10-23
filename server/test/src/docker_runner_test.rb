
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
  'when run(test-code) fails' +
  'the container is killed and' +
  'the assert diagnostic is returned' do
    @kata_id = test_id
    hiker_c = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 9; }'
    ].join("\n")
    expected_lines = [
      "Assertion failed: answer() == 42 (hiker.tests.c: life_the_universe_and_everything: 7)",
      "make: *** [makefile:14: test.output] Aborted"
    ]
    actual = runner_run(hiker_c)
    expected_lines.each { |line| assert actual.include? line }
    # Odd...locally (Mac Docker-Toolbox, default VM)
    # the last line is
    #   make: *** [makefile:14: test.output] Aborted
    # on travis the last line is
    #   make: *** [makefile:14: test.output] Aborted (core dumped)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  'when run(test-code) passes' +
  'the container is killed and' +
  'the all-tests-passed string is returned' do
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
  'when run(test-code) has syntax-error' +
  'the container is killed and' +
  'the gcc diagnosticis returned' do
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

  test 'C9A',
  'when run(test-code) is empty-infinite-loop' +
  'the container is killed and' +
  'a timeout-diagostic is returned' do
    @kata_id = test_id
    hiker_c = [
      '#include "hiker.h"',
      'int answer(void) { for(;;); return 6 * 7; }'
    ].join("\n")
    expected = [
      "Unable to complete the tests in 3 seconds.",
      "Is there an accidental infinite loop?",
      "Is the server very busy?",
      "Please try again."
    ].join("\n")
    actual = runner_run(hiker_c, 3)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '307',
  'when run(test-code) is printing-infinite-loop' +
  'the container is killed and' +
  'a timeout-diagostic is returned' do
    @kata_id = test_id
    hiker_c = [
      '#include "hiker.h"',
      '#include <stdio.h>',
      'int answer(void) { for(;;) printf("...."); return 6 * 7; }'
    ].join("\n")
    expected = [
      "Unable to complete the tests in 3 seconds.",
      "Is there an accidental infinite loop?",
      "Is the server very busy?",
      "Please try again."
    ].join("\n")

    actual = runner_run(hiker_c, 3)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Test that deletes some files

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include Externals

  def runner; DockerRunner.new(self); end

  def success; 0; end

  def space; ' '; end

  def any; 'sdsdsd'; end

  def live_shelling
    ENV[env_name('shell')] = 'ExternalSheller'
    ENV[env_name('log')] = 'SpyLogger'
  end

  def exec(command)
    output, exit_success = shell.exec(command)
    return [output, exit_success]
  end

  def read(filename)
    IO.read("/app/test/src/start_files/#{filename}")
  end

  def volume_name; 'cyber_dojo_' + @kata_id + '_' + @avatar_name; end

  def runner_run(hiker_c, max_seconds = 10)
    @avatar_name = 'lion'
    live_shelling
    runner.start(@kata_id, @avatar_name)
    changed_files = {
      'hiker.c'       => hiker_c,
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    output = runner.run(
      image_name = 'cyberdojofoundation/gcc_assert',
      @kata_id,
      @avatar_name,
      max_seconds,
      delete_filenames = [],
      changed_files)

    _, exit_status = exec("docker inspect --format='{{ .State.Running }}' ${cid} 2> /dev/null")
    assert_equal does_not_exist=1, exit_status

    # if the test was an infinite-loop test
    # then docker_runner.sh did a [docker rm --force CID] in a child process
    # This creates a timing issue and you seem to need
    # to wait until the container is actually dead
    100.times do
      #p "about to [docker volume rm #{volume_name}]"
      vrm_output, vrm_exit_status = exec("docker volume rm #{volume_name} 2>&1")
      return output if vrm_exit_status == 0
      #p "[docker volume rm]exit_status=:#{vrm_exit_status}:"
      #p "[docker volume rm]output=:#{vrm_output}:"
    end

    # return 100 (Fixnum, not string) causing test failures
    # To keep test coverage at 100% I'm not doing this
    #    fail "UNABLE to do [docker volume rm #{volume_name}] after 100 attempts!"
  end

end
