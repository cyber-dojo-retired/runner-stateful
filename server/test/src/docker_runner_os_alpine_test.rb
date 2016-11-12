require_relative './runner_test_base'
require_relative './docker_runner_os_helper'

class DockerRunnerOSAlpineTest < RunnerTestBase

  include DockerRunnerOsHelper

  def self.hex_prefix; '4D778'; end
  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0',
  '[Alpine] image is indeed Alpine and has user and group' do
    stdout = assert_cyber_dojo_sh_no_stderr 'cat /etc/issue'
    assert stdout.include?('Alpine'), stdout
    assert_user_exists
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '214',
  '[Alpine] container must have tini installed to do zombie reaping' do
    stdout = assert_cyber_dojo_sh_no_stderr 'ps'
    lines = stdout.strip.split("\n")
    # PID   USER     TIME   COMMAND
    #   1   root     0:00   sh
    #  25   nobody   0:00   sh -c ./cyber-dojo.sh
    #   |   |        |      |  |  |
    #   0   1        2      3  4  5 ...
    lines.shift
    procs = Hash[lines.collect { |line|
      atts = line.split
      pid = atts[0].to_i
      cmd = atts[3..-1].join(' ')
      [pid,cmd]
    }]
    refute_nil procs[1], 'no process at pid 1!'
    assert procs[1].include?('/sbin/tini'), 'no tini at pid 1'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '997',
  '[Alpine] container has access to cyber-dojo env-vars' do
    kata_id_env_vars_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0C9',
  '[Alpine] new_avatar has sandbox with ownership/permissions set' do
    new_avatar_sandbox_setup_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1FB',
  '[Alpine] new_avatar has starting-files in sandbox with ownership/permissions set' do
    new_avatar_starting_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  '[Alpine] unchanged files still exist and are unchanged' do
    unchanged_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  '[Alpine] deleted files are removed and all previous files are unchanged' do
    deleted_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '232',
  '[Alpine] new files are added with ownership/permissions and all previous files are unchanged' do
    new_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A7',
  '[Alpine] a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

end
