require_relative './runner_test_base'

class DockerRunnerUserGroupTest < RunnerTestBase

  def self.hex_prefix
    '8EC58'
  end

  def hex_setup
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
    stdout, _ = assert_run_completes_no_stderr({ 'cyber-dojo.sh' => 'getent passwd nobody' })
    assert stdout.start_with?(user), stdout
    stdout, _ = assert_run_completes_no_stderr({ 'cyber-dojo.sh' => 'getent group nogroup' })
    assert stdout.start_with?(group), stdout
  end

end

