
require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerAvatarTest < LibTestBase

  def self.hex
    'FEA56'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'before hello_avatar its volume does not exist,',
  'after hello_avatar it does' do
    refute volume_exists?
    _, status = hello_avatar
    assert_equal success, status
    assert volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A9',
  'before goodbye_avatar its volume exists,',
  'after goobye_avatar its does not' do
    hello_avatar
    goodbye_avatar
    refute volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  include DockerRunnerHelpers

end
