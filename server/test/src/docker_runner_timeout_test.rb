
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
    hello
    files['hiker.c'] = [
      '#include "hiker.h"',
      'int answer(void) { for(;;); return 6 * 7; }'
    ].join("\n")
    output, status = execute(files, max_seconds = 2)
    assert_equal '', output
    assert_equal timed_out_and_killed, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4D7',
  'when run(test-code) is printing-infinite-loop',
  'the container is killed and',
  'a timeout-diagostic is returned' do
    hello
    files['hiker.c'] = [
      '#include "hiker.h"',
      '#include <stdio.h>',
      'int answer(void) { for(;;) printf("...."); return 6 * 7; }'
    ].join("\n")
    output, status = execute(files, max_seconds = 2)
    assert_equal '', output
    assert_equal timed_out_and_killed, status
  end

  private

  include DockerRunnerHelpers

end

