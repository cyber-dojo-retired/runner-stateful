require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerLanguageTest < LibTestBase

  def self.hex
    '9D930'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'BB3',
  'when run(test-code) fails',
  'the container is killed and',
  'the assert diagnostic is returned' do
    runner_start
    expected_lines = [
      "Assertion failed: answer() == 42 (hiker.tests.c: life_the_universe_and_everything: 7)",
      "make: *** [makefile:14: test.output] Aborted"
    ]
    actual = runner_run(starting_files)
    expected_lines.each { |line| assert actual.include? line }
    # Odd...locally (Mac Docker-Toolbox, default VM)
    # the last line is
    #   make: *** [makefile:14: test.output] Aborted
    # on travis the last line is
    #   make: *** [makefile:14: test.output] Aborted (core dumped)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CDE',
  'when run(test-code) passes',
  'the container is killed and',
  'the all-tests-passed string is returned' do
    runner_start
    expected = "All tests passed\n"
    files = starting_files
    files['hiker.c'] = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 7; }'
    ].join("\n")
    actual = runner_run(files)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '13D',
  'when run(test-code) has syntax-error',
  'the container is killed and',
  'the gcc diagnosticis returned' do
    runner_start
    files = starting_files
    files['hiker.c'] = [
      '#include "hiker.h"',
      'int answer(void) { return 6 * 9sss; }'
    ].join("\n")
    expected = [
      "hiker.c: In function 'answer':",
      "hiker.c:2:31: error: invalid suffix \"sss\" on integer constant",
      " int answer(void) { return 6 * 9sss; }",
      "                               ^",
      "hiker.c:2:1: error: control reaches end of non-void function [-Werror=return-type]",
      " int answer(void) { return 6 * 9sss; }",
      " ^",
      "cc1: all warnings being treated as errors",
      "make: *** [makefile:17: test] Error 1"
    ].join("\n") + "\n"
    actual = runner_run(files)
    assert_equal expected, actual
  end

  private

  include DockerRunnerHelpers

end

