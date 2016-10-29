require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix
    '9D930'
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
  '[C(gcc),assert] (an Ubuntu-based image)' do
    output, _status = assert_run(files('gcc_assert'))
    assert output.include?('Assertion failed: answer() == 42'), output
    assert_user_nobody_exists
    assert_group_nogroup_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  '[Ruby,MiniTest] (an Alpine-based image)' do
    output, _status = assert_run(files('ruby_mini_test'))
    assert output.include?('1 runs, 1 assertions, 1 failures, 0 errors, 0 skips'), output
    assert_user_nobody_exists
    assert_group_nogroup_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    output, _status = assert_run(files('csharp_moq'))
    assert output.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), output
    assert_user_nobody_exists
    assert_group_nogroup_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    output, _status = assert_run(files('csharp_nunit'))
    assert output.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), output
    assert_user_nobody_exists
    assert_group_nogroup_exists
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_user_nobody_exists
    output, _ = assert_run({ 'cyber-dojo.sh' => 'getent passwd nobody' })
    assert output.start_with?('nobody'), output
  end

  def assert_group_nogroup_exists
    output, _ = assert_run({ 'cyber-dojo.sh' => 'getent group nogroup' })
    assert output.start_with?('nogroup'), output
  end

end

