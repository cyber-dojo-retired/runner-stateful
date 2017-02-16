require_relative 'test_base.rb'
require_relative 'os_helper'

class SharedFolderTest < TestBase

  include OsHelper

  def self.hex_prefix; 'B4A'; end

  def hex_setup
    set_image_name image_for_test
    new_kata
  end

  def hex_teardown
    old_kata
  end

  def self.kv_test(hex_suffix, *lines, &test_block)
    if runner_class == 'DockerKataVolumeRunner' ||
       runner_class == 'DockerKataContainerRunner'
      test(hex_suffix, *lines, &test_block)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kv_test 'B33',
  '[Alpine] first new_avatar event in a kata causes creation of /sandboxes/shared' do
    new_avatar('salmon')
    begin
      shared = '/sandboxes/shared'
      assert_cyber_dojo_sh "[ -d #{shared} ]"
    ensure
      old_avatar('salmon')
    end
  end

  kv_test 'A54',
  '[Alpine] shared sandbox creation is idempotent' do
    new_avatar('salmon')
    new_avatar('lion')
    begin
      shared = '/sandboxes/shared'
      assert_cyber_dojo_sh "[ -d #{shared} ]"
    ensure
      old_avatar('lion')
      old_avatar('salmon')
    end
  end

  kv_test '893',
  '[Alpine] /sandboxes/shared is writable by any avatar' do
    new_avatar('salmon')
    begin
      shared = '/sandboxes/shared'
      # sandbox's is owned by cyber-dojo
      stat_group = assert_cyber_dojo_sh("stat -c '%G' #{shared}").strip
      assert_equal 'cyber-dojo', stat_group
      # sandbox's permissions are set
      stat_perms = assert_cyber_dojo_sh("stat -c '%A' #{shared}").strip
      assert_equal 'drwxrwxr-x', stat_perms
    ensure
      old_avatar('salmon')
    end
  end

end
