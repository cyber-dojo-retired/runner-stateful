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
    runner_start
    output = runner_run(language_files('gcc_assert'))
    assert_equal "All tests passed\n", output
    assert user_nobody_exists?
    assert group_nogroup_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  '[Ruby,MiniTest] (an Alpine-based image) runs and has',
  'the user nobody and',
  'the group nogroup' do
    runner_start
    output = runner_run(language_files('ruby_mini_test'))
    assert output.include?('1 runs, 1 assertions, 0 failures, 0 errors, 0 skips')
    assert user_nobody_exists?
    assert group_nogroup_exists?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '99B',
  '[F#,NUnit] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    runner_start
    output = runner_run(language_files('fsharp_nunit'))
    assert output.include?('Tests run: 1, Errors: 0, Failures: 0, Inconclusive: 0')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    runner_start
    output = runner_run(language_files('csharp_nunit'))
    assert output.include?('Tests run: 1, Errors: 0, Failures: 0, Inconclusive: 0')
  end

  private

  def user_nobody_exists?
    user = runner_run({'cyber-dojo.sh' => 'getent passwd nobody'})
    user.start_with?('nobody')
  end

  def group_nogroup_exists?
    group = runner_run({'cyber-dojo.sh' => 'getent group nogroup'})
    group.start_with?('nogroup')
  end

  include DockerRunnerHelpers

end

