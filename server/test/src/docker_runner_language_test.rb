require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix; '9D930'; end
  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#,NUnit] runs (it sets HOME to location of sandbox in cyber-dojo.sh)' do
    stdout,stderr,status = runner_run(files('csharp_nunit'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
    assert_equal '', stderr
    assert_equal 1, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it sets HOME to location of sandbox in cyber-dojo.sh)' do
    stdout,stderr,status = runner_run(files('csharp_moq'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
    assert_equal '', stderr
    assert_equal 1, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '76D',
  '[gcc,assert] runs' do
    stdout,stderr,status = runner_run(files('gcc_assert'))
    assert_equal "makefile:14: recipe for target 'test.output' failed\n", stdout
    assert stderr.include?('Assertion failed: answer() == 42'), stderr
    assert_equal 2, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '358',
  '[Java,Cucumber] runs' do
    stdout,stderr,status = runner_run(files('java_cucumber'))
    assert stdout.include?('1 Scenarios (1 failed)'), stdout
    assert_equal '', stderr
    assert_equal 1, status
  end

end

