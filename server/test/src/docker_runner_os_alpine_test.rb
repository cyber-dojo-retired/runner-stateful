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
    stdout = assert_run_succeeds_no_stderr({ 'cyber-dojo.sh' => 'cat /etc/issue'})
    assert stdout.include?('Alpine'), stdout
    assert_user_exists
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

=begin
  test '214',
  '[Alpine] container must have tini installed to do zombie reaping' do
    stdout = assert_run_succeeds_no_stderr({ 'cyber-dojo.sh' => 'ps' })
    p stdout
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '782',
  '[Alpine] container has access to kata_id via ENV-VAR' do
    kata_id_env_var_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0C9',
  '[Alpine] newly created container has empty sandbox with ownership/permissions' do
    create_container_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1FB',
  '[Alpine] starting-files are copied into sandbox with ownership/permissions' do
    starting_files_test
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
