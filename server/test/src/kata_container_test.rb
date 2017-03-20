=begin
require_relative 'test_base.rb'
require_relative 'os_helper'

class KataContainerTest < TestBase

  include OsHelper

  def self.hex_prefix; '6ED'; end

  def hex_setup
    set_image_name image_for_test
    kata_new
  end

  def hex_teardown
    kata_old
  end

  def self.kc_test(hex_suffix, *lines, &test_block)
    if runner_class_name == 'SharedContainerRunner'
      test(hex_suffix, *lines, &test_block)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kc_test '3B1',
  '[Alpine] after kata_new the timeout script is in /usr/local/bin' do
    filename = 'timeout_cyber_dojo.sh'
    src = assert_docker_exec("cat /usr/local/bin/#{filename}")
    local_src = IO.read("/app/src/#{filename}")
    assert_equal local_src, src
  end

  kc_test '3B2',
  '[Ubuntu] after kata_new the timeout script is in /usr/local/bin' do
    filename = 'timeout_cyber_dojo.sh'
    src = assert_docker_exec("cat /usr/local/bin/#{filename}")
    local_src = IO.read("/app/src/#{filename}")
    assert_equal local_src, src
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kc_test '5F9',
  '[Alpine] after avatar_new(salmon)',
  'there is a linux user called salmon inside the kata container' do
    avatar_new('salmon')
    begin
      uid = assert_docker_exec('id -u salmon').strip
      assert_equal user_id('salmon'), uid
    ensure
      avatar_old('salmon')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  kc_test '2A8',
  '[Ubuntu] after avatar_new(salmon)',
  'there is a linux user called salmon inside the kata container' do
    avatar_new('salmon')
    begin
      uid = assert_docker_exec('id -u salmon').strip
      assert_equal user_id('salmon'), uid
    ensure
      avatar_old('salmon')
    end
  end

  private

  def container_name
    'cyber_dojo_kata_container_runner_' + kata_id
  end

end
=end