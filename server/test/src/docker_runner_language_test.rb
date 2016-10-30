require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix
    '9D930'
  end

  def hex_setup
    new_avatar
  end

  def hex_teardown
    old_avatar
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CA0',
  'an Alpine-based image runs [C(gcc),assert]' do
    src = files('gcc_assert')
    stdout, stderr = assert_run_completes(src)
    assert stderr.include?('Assertion failed: answer() == 42'), stderr
    assert_equal '', stdout

    src['cyber-dojo.sh'] = 'cat /etc/issue'
    stdout, _ = assert_run_completes_no_stderr(src)
    assert stdout.include?('Alpine'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  'an Ubuntu-based image runs [Java,Cucumber]' do
    src = files('java_cucumber')
    stdout, _ = assert_run_completes_no_stderr(src)
    assert stdout.include?('Hiker.feature:4 # Scenario: last earthling playing scrabble'), stdout

    src['cyber-dojo.sh'] = 'cat /etc/issue'
    stdout, _ = assert_run_completes_no_stderr(src)
    assert stdout.include?('Ubuntu'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
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

