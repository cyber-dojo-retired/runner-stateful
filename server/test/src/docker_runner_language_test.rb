require_relative './runner_test_base'

class DockerRunnerLanguageTest < RunnerTestBase

  def self.hex_prefix; '9D930'; end
  def hex_teardown; old_avatar; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '182',
  '[C#-NUnit] runs (it needs to pick up HOME from the current user)' do
    @image_name = 'cyberdojofoundation/csharp_nunit'
    new_kata
    new_avatar
    stdout, _ = assert_run_completes_no_stderr(files('csharp_nunit'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'C87',
  '[C#,Moq] runs (it explicitly names /sandbox in cyber-dojo.sh)' do
    @image_name = 'cyberdojofoundation/csharp_nunit'
    new_kata
    new_avatar
    stdout, _ = assert_run_completes_no_stderr(files('csharp_moq'))
    assert stdout.include?('Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0'), stdout
  end

end

