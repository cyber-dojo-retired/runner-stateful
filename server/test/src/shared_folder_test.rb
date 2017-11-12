require_relative 'test_base'
require_relative 'os_helper'

class SharedFolderTest < TestBase

  include OsHelper

  def self.hex_prefix
    'B4A'
  end

  def hex_setup
    set_image_name image_for_test
    kata_new
  end

  def hex_teardown
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'B33',
  %w( [Alpine] first avatar_new event in a kata causes creation of /tmp/sandboxes/shared ) do
    as('salmon') {
      shared = '/tmp/sandboxes/shared'
      assert_cyber_dojo_sh "[ -d #{shared} ]"
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'A54',
  %w( [Alpine] shared sandbox creation is idempotent ) do
    as('lion') {
      as('salmon') {
        shared = '/tmp/sandboxes/shared'
        assert_cyber_dojo_sh "[ -d #{shared} ]"
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '893',
  %w( [Alpine] /tmp/sandboxes/shared is writable by any avatar ) do
    as('salmon') {
      shared = '/tmp/sandboxes/shared'
      # sandbox's is owned by cyber-dojo
      stat_group = assert_cyber_dojo_sh("stat -c '%G' #{shared}").strip
      assert_equal 'cyber-dojo', stat_group
      # sandbox's permissions are set
      stat_perms = assert_cyber_dojo_sh("stat -c '%A' #{shared}").strip
      assert_equal 'drwxrwxr-x', stat_perms
    }
  end

end
