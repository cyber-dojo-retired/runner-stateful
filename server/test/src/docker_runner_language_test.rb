require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerLanguageTest < LibTestBase

  def self.hex
    '9D930'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  'alpine-based image [C(gcc),assert]' do
    runner_start
    expected = "All tests passed\n"
    files = starting_files
    actual = runner_run(files)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test
  # ubuntu-based image (??)

  # test
  # (F#,NUnit) which explicitly names /sandbox in cyber-dojo.sh

  # test
  # (C#-NUnit) which needs to pick up HOME from the _current_ user

  private

  include DockerRunnerHelpers

end

