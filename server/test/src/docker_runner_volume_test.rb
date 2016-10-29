require_relative './runner_test_base'

class DockerRunnerVolumeTest < RunnerTestBase

  def self.hex_prefix
    'FEA56'
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

end
