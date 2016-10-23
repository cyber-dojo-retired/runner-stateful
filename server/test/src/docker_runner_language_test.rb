require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerLanguageTest < LibTestBase

  def self.hex
    '9D930'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  'Ubuntu-based image [C(gcc),assert]' do
    runner_start
    actual = runner_run(language_files('gcc_assert'))
    assert_equal "All tests passed\n", actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5F0',
  'Alpine-based [Ruby,MiniTest]' do
    runner_start
    output = runner_run(language_files('ruby_mini_test'))
    assert output.include?('1 runs, 1 assertions, 0 failures, 0 errors, 0 skips')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

=begin
  test '99B',
  '(F#,NUnit) which explicitly names /sandbox in cyber-dojo.sh' do
    runner_start
    files = language_files('fsharp_nunit')
    output = runner_run(files)
    #expected = "All tests passed\n"
    #assert output.include?('1 runs, 1 assertions, 0 failures, 0 errors, 0 skips')
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test
  # (C#-NUnit) which needs to pick up HOME from the _current_ user

  private

  include DockerRunnerHelpers

end

