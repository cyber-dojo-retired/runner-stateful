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

  private

  def kata_setup
    cdf = 'cyberdojofoundation'
    @image_name = "#{cdf}/csharp_nunit" if test_name.start_with?('[C#,NUnit]')
    @image_name = "#{cdf}/csharp_moq" if test_name.start_with?('[C#,Moq]')
    fail "cannot set @image_name from test_name" if @image_name.nil?
    new_kata
    new_avatar
  end

  def kata_teardown
    old_avatar
    old_kata
  end

end

