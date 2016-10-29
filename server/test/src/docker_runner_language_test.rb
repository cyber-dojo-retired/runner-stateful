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

  test 'CDE',
  '[C(gcc),assert] (an Ubuntu-based image)' do
    output, _ = assert_run_completes(files('gcc_assert'))
    assert output.include?('Assertion failed: answer() == 42'), output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  '[Ruby,MiniTest] (an Alpine-based image)' do
    output, _ = assert_run_completes(files('ruby_mini_test'))
    assert output.include?('1 runs, 1 assertions, 1 failures, 0 errors, 0 skips'), output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    output, _ = assert_run_completes(files('csharp_moq'))
    assert output.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    output, _ = assert_run_completes(files('csharp_nunit'))
    assert output.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), output
  end

end

