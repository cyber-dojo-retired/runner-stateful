require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix; '9D930'; end
  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#,NUnit] runs (it needs to pick up HOME from the current user)' do
    stdout, _ = assert_run_completes_no_stderr(files('csharp_nunit'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    stdout, _ = assert_run_completes_no_stderr(files('csharp_moq'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

end

