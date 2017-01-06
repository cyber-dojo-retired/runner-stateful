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
  '[Alpine] after new_avatar(salmon)',
  'there is a linux user called salmon inside the kata container' do
    new_avatar(salmon)
    begin
      whoami = assert_docker_exec 'su - salmon -c whoami'
      assert_equal 'salmon', whoami.strip
    ensure
      old_avatar(salmon)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kc_test '2A8',
  '[Ubuntu] after new_avatar(salmon)',
  'there is a linux user called salmon inside the kata container' do
    new_avatar(salmon)
    begin
      whoami = assert_docker_exec 'su - salmon -c whoami'
      assert_equal 'salmon', whoami.strip
    ensure
      old_avatar(salmon)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def salmon
    { avatar_name:'salmon' }
  end


end
