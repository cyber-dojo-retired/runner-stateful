require_relative './runner_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerAvatarTest < RunnerTestBase

  def self.hex_prefix
    'FEA56'
  end

  def hex_setup
    ENV[env_name('log')] = 'NullLogger'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  "before hello volume does not exist,",
  'after hello it does' do
    refute volume_exists?
    _, status = hello
    assert_equal success, status
    assert volume_exists?
    goodbye
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A9',
  "before goodbye volume exists,",
  'after goobye its does not' do
    hello
    goodbye
    refute volume_exists?
  end

  private

  include DockerRunnerHelpers

end
