require_relative 'test_base'
require_relative 'os_helper'

class RunUbuntuKataTest < TestBase

  include OsHelper

  def self.hex_prefix; '2C3B9'; end

  def hex_setup
    set_image_name image_for_test
    new_kata
  end

  def hex_teardown
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA1',
  '[Ubuntu] image is indeed based on Ubuntu' do
    etc_issue = assert_docker_exec_no_stderr 'cat /etc/issue'
    assert etc_issue.include?('Ubuntu'), etc_issue
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '268',
  "[Ubuntu] none of the 64 avatar's uid's are already taken" do
    refute_user_ids_exist
  end

end
