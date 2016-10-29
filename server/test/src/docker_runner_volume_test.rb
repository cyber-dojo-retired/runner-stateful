require_relative './runner_test_base'

class DockerRunnerVolumeTest < RunnerTestBase

  def self.hex_prefix
    'FEA56'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  "before new_avatar volume does not exist,",
  'after new_avatar it does' do
    refute volume_exists?
    _, status = new_avatar
    begin
      assert_equal success, status
      assert volume_exists?
    ensure
      old_avatar
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9A9',
  "before old_avatar volume exists,",
  'after old_avatar its does not' do
    new_avatar
    old_avatar
    refute volume_exists?
  end

end
