
require_relative './lib_test_base'
require_relative './docker_runner_helpers'

class DockerRunnerTimeoutTest < LibTestBase

  def self.hex
    '45B57'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B2B',
  'when run(test-code) is empty-infinite-loop',
  'the container is killed and',
  'a timeout-diagostic is returned' do
    runner_start
    files = language_files('gcc_assert')
    files['hiker.c'] = [
      '#include "hiker.h"',
      'int answer(void) { for(;;); return 6 * 7; }'
    ].join("\n")
    expected = [
      "Unable to complete the tests in 2 seconds.",
      "Is there an accidental infinite loop?",
      "Is the server very busy?",
      "Please try again."
    ].join("\n")
    actual = runner_run(files, [], 2)
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4D7',
  'when run(test-code) is printing-infinite-loop',
  'the container is killed and',
  'a timeout-diagostic is returned' do
    runner_start
    files = language_files('gcc_assert')
    files['hiker.c'] = [
      '#include "hiker.h"',
      '#include <stdio.h>',
      'int answer(void) { for(;;) printf("...."); return 6 * 7; }'
    ].join("\n")
    expected = [
      "Unable to complete the tests in 2 seconds.",
      "Is there an accidental infinite loop?",
      "Is the server very busy?",
      "Please try again."
    ].join("\n")
    actual = runner_run(files, delete_filenames = [], max_seconds = 2)
    assert_equal expected, actual
  end

  private

  include DockerRunnerHelpers

end

