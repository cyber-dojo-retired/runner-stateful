require_relative 'test_base'
require_relative 'os_helper'

class RunAlpineKataTest < TestBase

  include OsHelper

  def self.hex_prefix; '89079'; end

  def hex_setup
    set_image_name image_for_test
    new_kata
  end

  def hex_teardown
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0',
  '[Alpine] image is indeed based on Alpine' do
    etc_issue = assert_docker_exec 'cat /etc/issue'
    assert etc_issue.include?('Alpine'), etc_issue
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '267',
  "[Alpine] none of the 64 avatar's uid's are already taken" do
    refute_user_ids_exist
  end

end
