require_relative 'test_base'
require_relative 'os_helper'

class RunOSTest < TestBase

  include OsHelper

  def self.hex_prefix
    '3759D'
  end

  def hex_setup
    kata_setup
  end

  def hex_teardown
    kata_teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def self.os_test(hex_suffix, *lines, &test_block)
    alpine_lines = ['[Alpine]'] + lines
    test(hex_suffix+'0', *alpine_lines, &test_block)
    ubuntu_lines = ['[Ubuntu]'] + lines
    test(hex_suffix+'1', *ubuntu_lines, &test_block)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test 'A88',
  'container has init process running on pid 1' do
    pid_1_process_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '997',
  'container has access to cyber-dojo env-vars' do
    kata_id_env_vars_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '267',
  'all of the 64 avatar users already exist' do
    assert_avatar_users_exist
  end


  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '582',
  'has group used for dir/file ownership' do
    assert_group_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '2A0',
  'avatar_new has HOME set off /home' do
    avatar_new_home_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '0C9', %w(
  avatar_new has its own sandbox
  with owner/group/permissions set
  ) do
    avatar_new_sandbox_setup_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '1FB', %w(
  avatar_new has starting-files in its sandbox
  with owner/group/permissions set
  ) do
    avatar_new_starting_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '4E8',
  'unchanged files still exist and are unchanged' do
    unchanged_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '385',
  'deleted files are removed',
  'and all previous files are unchanged' do
    deleted_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '232',
  'new files are added with owner/group/permissions',
  'and all previous files are unchanged' do
    new_files_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test '9A7',
  'a changed file is resaved and its size and time-stamp updates',
  'and all previous files are unchanged' do
    changed_file_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test 'D7C',
  'is ulimited' do
    ulimit_test
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  os_test 'B25',
  'file date-time stamps have sub-microsecond granularity' do
    datetime_stamps_granularity_test
  end

end
