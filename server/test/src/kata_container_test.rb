require_relative 'test_base.rb'
require_relative 'os_helper'

class KataContainerTest < TestBase

  include OsHelper

  def self.hex_prefix; '6ED'; end

  def hex_setup
    set_image_name image_for_test
    new_kata
  end

  def hex_teardown
    old_kata
  end

  def self.kc_test(hex_suffix, *lines, &test_block)
    if runner_class == 'DockerKataContainerRunner'
      test(hex_suffix, *lines, &test_block)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kc_test '5F9',
  '[Alpine] after new_avatar there is an avatar-user' do
    cheetah_arg = { avatar_name:'cheetah' }
    new_avatar(cheetah_arg)
    begin
      stdout = assert_cyber_dojo_sh_no_stderr 'su - cheetah -c whoami', cheetah_arg
      assert_equal 'cheetah', stdout.strip
    ensure
      old_avatar({ avatar_name:'cheetah' })
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kc_test '2A8',
  '[Ubuntu] after new_avatar there is an avatar-user' do
    cheetah_arg = { avatar_name:'cheetah' }
    new_avatar(cheetah_arg)
    begin
      stdout = assert_cyber_dojo_sh_no_stderr 'su - cheetah -c whoami', cheetah_arg
      assert_equal 'cheetah', stdout.strip
    ensure
      old_avatar({ avatar_name:'cheetah' })
    end
  end


end
