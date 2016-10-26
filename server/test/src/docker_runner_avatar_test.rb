require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerAvatarTest < LibTestBase

  def self.hex
    'FEA56'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  "before hello avatar's' volume does not exist,",
  'after hello it does' do
    refute volume_exists?
    _, status = hello
    assert_equal success, status
    assert volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A9',
  "before goodbye avatar's volume exists,",
  'after goobye its does not' do
    hello
    goodbye
    refute volume_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  private

  include DockerRunnerHelpers

end
