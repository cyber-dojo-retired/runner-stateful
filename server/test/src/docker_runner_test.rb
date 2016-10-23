
require_relative './lib_test_base'
require_relative './mock_sheller'
require_relative './null_logger'

class DockerRunnerTest < LibTestBase

  # TODO: expose container's cid and ensure [docker rm #{cid}] happens in external_teardown

  def self.hex
    '9D930'
  end

  def external_setup
    ENV[env_name('shell')] = 'MockSheller'
    @rm_volume = ''
  end

  def external_teardown
    if shell.class.name == 'ExternalSheller'
      remove_volume(@rm_volume) unless @rm_volume == ''
    end
    if shell.class.name == 'MockSheller'
      shell.teardown
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B71',
  'pulled?(image_name) is false when image_name has not yet been pulled' do
    no_gcc_assert = [
      "REPOSITORY                         TAG     IMAGE ID      CREATED         SIZE",
      "cyberdojofoundation/java_cucumber  latest  06aa46aad63d  6 weeks ago     881.7 MB",
      "cyberdojo/runner                   1.12.2  a531a83580c9  18 minutes ago  56.05 MB"
    ].join("\n")
    shell.mock_exec(['docker images'], no_gcc_assert, success)
    refute runner.pulled?(gcc_assert_image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '94E',
  'pulled?(image) is true when image_name has already been pulled' do
    has_gcc_assert = [
      "REPOSITORY                          TAG      IMAGE ID      CREATED         SIZE",
      "cyberdojofoundation/java_cucumber   latest   06aa46aad63d  6 weeks ago     881.7 MB",
      "cyberdojo/runner                    1.12.2   a531a83580c9  18 minutes ago  56.05 MB",
      "#{gcc_assert_image_name}            latest   da213d286ec5  4 months ago    99.16 MB"
    ].join("\n")
    shell.mock_exec(['docker images'], has_gcc_assert, success)
    assert runner.pulled?(gcc_assert_image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DA5',
  'pull(image_name) issues shell(docker pull) command' do
    shell.mock_exec(["docker pull #{gcc_assert_image_name}"], any, success)
    output, exit_status = runner.pull(gcc_assert_image_name)
    assert_equal any, output
    assert_equal success, exit_status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # start
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'F2E',
  'start(kata_id,avatar_name) issues shell(docker create volume) command' do
    shell.mock_exec(["docker volume create --name #{volume_name}"], any, success)
    output, exit_status = runner.start(kata_id, avatar_name)
    assert_equal any, output
    assert_equal success, exit_status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'start creates a docker-volume' do
    live_shelling
    runner.start(kata_id, avatar_name)
    output, exit_status = exec('docker volume ls')
    assert_equal success, exit_status
    assert output.include? volume_name
    exec("docker volume rm #{volume_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BB3',
  'when run(test-code) fails',
  'the container is killed and',
  'the assert diagnostic is returned' do
    live_shelling
    runner_start
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
  'when run(test-code) passes',
  'the container is killed and',
  'the all-tests-passed string is returned' do
    live_shelling
    runner_start
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
  'when run(test-code) has syntax-error',
  'the container is killed and',
  'the gcc diagnosticis returned' do
    live_shelling
    runner_start
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
  'when run(test-code) is empty-infinite-loop',
  'the container is killed and',
  'a timeout-diagostic is returned' do
    live_shelling
    runner_start
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
  'when run(test-code) is printing-infinite-loop',
  'the container is killed and',
  'a timeout-diagostic is returned' do
    live_shelling
    runner_start
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

  def runner_start
    output, exit_status = runner.start(kata_id, avatar_name)
    assert_equal success, exit_status
    @rm_volume = output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner_run(hiker_c, max_seconds = 10)
    changed_files = {
      'hiker.c'       => hiker_c,
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    output = runner.run(
      gcc_assert_image_name,
      kata_id,
      avatar_name,
      max_seconds,
      delete_filenames = [],
      changed_files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_volume(name)
    # docker_runner.sh does [docker rm --force ${cid}] in a child process.
    # This has a race condition so you need to wait
    # until the container (which has the volume mounted)
    # is 'actually' removed before you can remove the volume.
    100.times do
      #p "about to [docker volume rm #{name}]"
      output, exit_status = exec("docker volume rm #{name} 2>&1")
      break if exit_status == success
      #p "[docker volume rm]exit_status=:#{exit_status}:"
      #p "[docker volume rm]output=:#{output}:"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def live_shelling
    ENV[env_name('shell')] = 'ExternalSheller'
    ENV[env_name('log'  )] = 'NullLogger'
  end

  def exec(command)
    output, exit_success = shell.exec(command)
    return [output, exit_success]
  end

  def read(filename)
    IO.read("/app/test/src/start_files/#{filename}")
  end

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def any; 'sdsdsd'; end
  def gcc_assert_image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; test_id; end
  def avatar_name; 'lion'; end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end

end
