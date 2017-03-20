require_relative 'test_base.rb'
require_relative 'os_helper'

class SharedFolderTest < TestBase

  include OsHelper

  def self.hex_prefix; 'B4A'; end

  def hex_setup
    set_image_name image_for_test
    kata_new
  end

  def hex_teardown
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B33',
  '[Alpine] first avatar_new event in a kata causes creation of /sandboxes/shared' do
    avatar_new('salmon')
    begin
      shared = '/sandboxes/shared'
      assert_cyber_dojo_sh "[ -d #{shared} ]"
    ensure
      avatar_old('salmon')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A54',
  '[Alpine] shared sandbox creation is idempotent' do
    avatar_new('salmon')
    avatar_new('lion')
    begin
      shared = '/sandboxes/shared'
      assert_cyber_dojo_sh "[ -d #{shared} ]"
    ensure
      avatar_old('lion')
      avatar_old('salmon')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '893',
  '[Alpine] /sandboxes/shared is writable by any avatar' do
    avatar_new('salmon')
    begin
      shared = '/sandboxes/shared'
      # sandbox's is owned by cyber-dojo
      stat_group = assert_cyber_dojo_sh("stat -c '%G' #{shared}").strip
      assert_equal 'cyber-dojo', stat_group
      # sandbox's permissions are set
      stat_perms = assert_cyber_dojo_sh("stat -c '%A' #{shared}").strip
      assert_equal 'drwxrwxr-x', stat_perms
    ensure
      avatar_old('salmon')
    end
  end

end
