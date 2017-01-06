require_relative 'test_base'
require_relative 'os_helper'

class RunUbuntuTest < TestBase

  include OsHelper

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
  '[Ubuntu] image is indeed based on Ubuntu' do
    stdout = assert_cyber_dojo_sh_no_stderr 'cat /etc/issue'
    assert stdout.include?('Ubuntu'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

=begin # broken because sss_run() needs avatar to exist
  test '268',
  "[Ubuntu] none of the 64 avatar's uid's are already taken" do
    refute_user_ids_exist
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '583',
  '[Ubuntu] has group used for dir/file ownership' do
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0CA',
  '[Ubuntu] new_avatar has its own sandbox with owner/group/permissions set' do
    new_avatar_sandbox_setup_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1FC',
  '[Ubuntu] new_avatar has starting-files in its sandbox with owner/group/permissions set' do
    new_avatar_starting_files_test
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
  '[Ubuntu] new files are added with owner/group/permissions and all previous files are unchanged' do
    new_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A8',
  '[Ubuntu] a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

end
