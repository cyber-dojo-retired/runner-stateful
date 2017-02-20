require_relative 'test_base'
require_relative 'os_helper'

class RunAlpineTest < TestBase

  include OsHelper

  def self.hex_prefix; '4D778'; end

  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '997',
  '[Alpine] container has access to cyber-dojo env-vars' do
    kata_id_env_vars_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '582',
  '[Alpine] has group used for dir/file ownership' do
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '2A0',
  '[Alpine] new_avatar has HOME set off /home' do
    new_avatar_home_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '0C9',
  '[Alpine] new_avatar has its own sandbox with owner/group/permissions set' do
    new_avatar_sandbox_setup_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '1FB',
  '[Alpine] new_avatar has starting-files in its sandbox with owner/group/permissions set' do
    new_avatar_starting_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4E8',
  '[Alpine] unchanged files still exist and are unchanged' do
    unchanged_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '385',
  '[Alpine] deleted files are removed',
  'and all previous files are unchanged' do
    deleted_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '232',
  '[Alpine] new files are added with owner/group/permissions',
  'and all previous files are unchanged' do
    new_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A7',
  '[Alpine] a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D7C',
  '[Alpine] max number of processes is ulimited' do
    max_processes_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3B7',
  '[Alpine] max core size is ulimited' do
    max_core_size_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BC6',
  '[Alpine] max number of files is ulimited' do
    max_number_of_files_test
  end

end
