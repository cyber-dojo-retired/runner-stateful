
require_relative './lib_test_base'
require_relative './mock_sheller'
require_relative './null_logger'

class DockerRunnerTest < LibTestBase

  # TODO: expose container's cid and ensure [docker rm #{cid}] happens in external_teardown

  def self.hex
    '9D930'
  end

  def external_setup
    assert_equal 'ExternalSheller', shell.class.name
    ENV[env_name('log')] = 'NullLogger'
    @rm_volume = ''
  end

  def external_teardown
    remove_volume(@rm_volume) unless @rm_volume == ''
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # start
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'start creates a docker-volume' do
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
    runner_start
    expected_lines = [
      "Assertion failed: answer() == 42 (hiker.tests.c: life_the_universe_and_everything: 7)",
      "make: *** [makefile:14: test.output] Aborted"
    ]
    actual = runner_run(starting_files)
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
    runner_start
    expected = "All tests passed\n"
    files = starting_files
    files['hiker.c'] = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 7; }'
    ].join("\n")
    actual = runner_run(files)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '13D',
  'when run(test-code) has syntax-error',
  'the container is killed and',
  'the gcc diagnosticis returned' do
    runner_start
    files = starting_files
    files['hiker.c'] = [
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
    actual = runner_run(files)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  'deleted files get deleted' do
    runner_start
    files = starting_files
    files['cyber-dojo.sh'] = 'ls'
    ls_output = runner_run(files)
    before_filenames = ls_output.split
    ls_output = runner_run({}, [ 'makefile' ])
    after_filenames = ls_output.split
    deleted_filenames = before_filenames - after_filenames
    assert_equal [ 'makefile'], deleted_filenames
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  'unchanged files dont get resaved' do
    runner_start
    files = starting_files
    files['cyber-dojo.sh'] = 'ls -el'
    ls_output = runner_run(files)
    #puts ls_output
    #IN PROGRESS
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test added files get added
  # test changed files get resaved

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include Externals

  def runner_start
    output, exit_status = runner.start(kata_id, avatar_name)
    assert_equal success, exit_status
    @rm_volume = output.strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner_run(changed_files, delete_filenames = [], max_seconds = 3)
    output = runner.run(
      gcc_assert_image_name,
      kata_id,
      avatar_name,
      max_seconds,
      delete_filenames,
      changed_files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def starting_files
    {
      'hiker.c'       => read('hiker.c'),
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
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

  def exec(command)
    output, exit_success = shell.exec(command)
    return [output, exit_success]
  end

  def read(filename)
    IO.read("/app/test/src/start_files/#{filename}")
  end

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def gcc_assert_image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; test_id; end
  def avatar_name; 'lion'; end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end

end

