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
    @expected = "Assertion failed: answer() == 42"
    assert_runs 'gcc_assert'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  '[Ruby,MiniTest] (an Alpine-based image)' do
    @expected = '1 runs, 1 assertions, 1 failures, 0 errors, 0 skips'
    assert_runs 'ruby_mini_test'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    @expected = 'Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'
    assert_runs 'csharp_moq'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    @expected = 'Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'
    assert_runs 'csharp_nunit'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_runs(dir)
    refute_nil @expected
    output, _status = assert_execute(files(dir))
    assert output.include?(@expected), output
    output, _ = assert_execute({ 'cyber-dojo.sh' => 'getent passwd nobody' })
    output.start_with?('nobody')
    output, _ = assert_execute({ 'cyber-dojo.sh' => 'getent group nogroup' })
    output.start_with?('nogroup')
  end

end

