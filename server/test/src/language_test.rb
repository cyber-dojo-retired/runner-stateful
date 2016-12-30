require_relative 'test_base'

class LanguageTest < TestBase

  def self.hex_prefix; '9D930'; end
  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#,NUnit] runs (it sets HOME to location of sandbox in cyber-dojo.sh)' do
    runner_run(files('csharp_nunit'))
    assert_stdout_include('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0')
    assert_stderr ''
    assert_status 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it sets HOME to location of sandbox in cyber-dojo.sh)' do
    runner_run(files('csharp_moq'))
    assert_stdout_include('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0')
    assert_stderr ''
    assert_status 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '76D',
  '[gcc,assert] runs' do
    runner_run(files('gcc_assert'))
    assert_stdout "makefile:14: recipe for target 'test.output' failed\n"
    assert_stderr_include 'Assertion failed: answer() == 42'
    assert_status 2
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '358',
  '[Java,Cucumber] runs' do
    runner_run(files('java_cucumber'))
    assert_stdout_include '1 Scenarios (1 failed)'
    assert_stderr ''
    assert_status 1
  end

end

