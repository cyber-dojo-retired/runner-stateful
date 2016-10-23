
require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerInfrastructureTest < LibTestBase

  def self.hex
    '4D87A'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'start creates a docker-volume' do
    runner_start
    output, exit_status = exec('docker volume ls')
    assert_equal success, exit_status
    assert output.include? volume_name
    exec("docker volume rm #{volume_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  'deleted files get deleted' do
    runner_start
    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls'
    ls_output = runner_run(files)
    before_filenames = ls_output.split
    ls_output = runner_run({}, max_seconds = 10, [ 'makefile' ])
    after_filenames = ls_output.split
    deleted_filenames = before_filenames - after_filenames
    assert_equal [ 'makefile' ], deleted_filenames
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  'unchanged files dont get resaved' do
    runner_start
    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls -el'
    ls_output = runner_run(files)
    # UNFINISHED...
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test added files get added

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test changed files get resaved

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include DockerRunnerHelpers

end

