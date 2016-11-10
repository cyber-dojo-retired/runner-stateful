require_relative './runner_test_base'
require_relative './docker_runner_os_helper'

class DockerRunnerOSUbuntuTest < RunnerTestBase

  include DockerRunnerOsHelper

  def self.hex_prefix; '5A631'; end
  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A95',
  '[Ubuntu] container has access to cyber-dojo env-vars' do
    kata_id_env_vars_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA1',
  '[Ubuntu] image is indeed Alpine and has user:nobody and group:nogroup' do
    stdout = assert_cyber_dojo_sh_no_stderr 'cat /etc/issue'
    assert stdout.include?('Ubuntu'), stdout
    assert_user_exists
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0CA',
  '[Ubuntu] new_avatar has non-empty sandbox with ownership/permissions set' do
    new_avatar_setup_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1FC',
  '[Ubuntu] starting-files are copied into sandbox with ownership/permissions set' do
    starting_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E9',
  '[Ubuntu] unchanged files still exist and are unchanged' do
    unchanged_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '386',
  '[Ubuntu] deleted files are removed and all previous files are unchanged' do
    deleted_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '233',
  '[Ubuntu] new files are added with ownership/permissions and all previous files are unchanged' do
    new_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A8',
  '[Ubuntu] a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

end
