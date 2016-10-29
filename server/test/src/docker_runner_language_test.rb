require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix
    '9D930'
  end

  def hex_setup
    hello
  end

  def hex_teardown
    goodbye
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0',
  '[C(gcc),assert] (an Ubuntu-based image)' do
    stdout, stderr = assert_run_completes(files('gcc_assert'))
    assert stderr.include?('Assertion failed: answer() == 42'), stderr
    assert_equal '', stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  '[Ruby,MiniTest] (an Alpine-based image)' do
    stdout, _ = assert_run_completes_no_stderr(files('ruby_mini_test'))
    assert stdout.include?('1 runs, 1 assertions, 1 failures, 0 errors, 0 skips'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    stdout, _ = assert_run_completes_no_stderr(files('csharp_moq'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    stdout, _ = assert_run_completes_no_stderr(files('csharp_nunit'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

end

