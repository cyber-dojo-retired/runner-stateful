require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix; '9D930'; end
  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#,NUnit] runs (it sets HOME to location of sandbox in cyber-dojo.sh)' do
    stdout,_ = assert_run_succeeds_no_stderr(files('csharp_nunit'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it sets HOME to location of sandbox in cyber-dojo.sh)' do
    stdout,_ = assert_run_succeeds_no_stderr(files('csharp_moq'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '76D',
  '[gcc,assert] runs' do
    _,stderr = assert_run_succeeds(files('gcc_assert'))
    assert stderr.include?('Assertion failed: answer() == 42'), stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '358',
  '[Java,Cucumber] runs' do
    stdout,_ = assert_run_succeeds_no_stderr(files('java_cucumber'))
    assert stdout.include?('1 Scenarios (1 failed)'), stdout
  end

end

