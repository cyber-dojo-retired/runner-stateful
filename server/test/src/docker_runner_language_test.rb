require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerLanguageTest < LibTestBase

  def self.hex
    '9D930'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  '[C(gcc),assert] (an Ubuntu-based image) runs and has',
  'the user nobody and',
  'the group nogroup' do
    @expected = "All tests passed\n"
    assert_runs 'gcc_assert'
    assert user_nobody_exists?
    assert group_nogroup_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  '[Ruby,MiniTest] (an Alpine-based image) runs and has',
  'the user nobody and',
  'the group nogroup' do
    @expected = '1 runs, 1 assertions, 0 failures, 0 errors, 0 skips'
    assert_runs 'ruby_mini_test'
    assert user_nobody_exists?
    assert group_nogroup_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '99B',
  '[F#,NUnit] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    @expected = 'Tests run: 1, Errors: 0, Failures: 0, Inconclusive: 0'
    assert_runs 'fsharp_nunit'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    @expected = 'Tests run: 1, Errors: 0, Failures: 0, Inconclusive: 0'
    assert_runs 'csharp_nunit'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_runs(dir)
    runner_new_avatar
    output, status = runner_run(language_files(dir))
    assert_equal success, status
    assert output.include?(@expected), output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user_nobody_exists?
    user, status = runner_run({'cyber-dojo.sh' => 'getent passwd nobody'})
    assert_equal success, status
    user.start_with?('nobody')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def group_nogroup_exists?
    group, status = runner_run({'cyber-dojo.sh' => 'getent group nogroup'})
    assert_equal success, status
    group.start_with?('nogroup')
  end

  include DockerRunnerHelpers

end

