
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
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  'deleted files get deleted and all previous files still exist' do
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

  test '232',
  'new files get added and all previous files still exist' do
    runner_start
    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls'
    ls_output = runner_run(files)
    before_filenames = ls_output.split
    files = { 'newfile.txt' => 'hello world' }
    ls_output = runner_run(files)
    after_filenames = ls_output.split
    new_filenames = after_filenames - before_filenames
    assert_equal [ 'newfile.txt' ], new_filenames
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  'unchanged files dont get resaved' do
    runner_start
    files = language_files('gcc_assert')
    files['cyber-dojo.sh'] = 'ls -el'
    before_ls = runner_run(files)
    after_ls = runner_run({})
    assert_equal before_ls, after_ls
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test '9A7'
  # 'changed files get resaved' do
  # lines like this
  # -rwxr-xr-x 1 nobody root 19 Sun Oct 23 19:15:35 2016 cyber-dojo.sh
  # 0          1 2      3    4  5   6   7  8        9    10
  #before = ls_output.split("\n")
  #info = lines[0].split
  #p "permissions:#{info[0]}"
  #p "???#{info[1]}"
  #p "owner:#{info[2]}"
  #p "group:#{info[3]}"
  #p "name:#{info[10]}"
  # end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include DockerRunnerHelpers

end

