require_relative './runner_test_base'

class DockerRunnerUserGroupTest < RunnerTestBase

  def self.hex_prefix
    '8EC58'
  end

  def hex_setup
    ENV[env_name('log')] = 'NullLogger'
    assert_equal 'NullLogger', log.class.name
    assert_equal 'ExternalSheller', shell.class.name
    hello
  end

  def hex_teardown
    goodbye
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  "Ubuntu-based image has runner's user and group" do
    assert_user_group_exists_in('cyberdojofoundation/gcc_assert')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  "Alpine-based image has runner's user and group" do
    assert_user_group_exists_in('cyberdojofoundation/ruby_mini_test')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_user_group_exists_in(image_name)
    @image_name = image_name
    output, _ = assert_run_completes({ 'cyber-dojo.sh' => 'getent passwd nobody' })
    assert output.start_with?(user), output
    output, _ = assert_run_completes({ 'cyber-dojo.sh' => 'getent group nogroup' })
    assert output.start_with?(group), output
  end

end

