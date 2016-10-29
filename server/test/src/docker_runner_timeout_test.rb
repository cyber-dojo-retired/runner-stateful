require_relative './runner_test_base'

class DockerRunnerTimeoutTest < RunnerTestBase

  def self.hex_prefix
    '45B57'
  end

  def hex_setup
    hello
  end

  def hex_teardown
    goodbye
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B2B',
  'when run(test-code) does not complete in max_seconds',
  'and does not produce output,',
  'the output is empty, and',
  'the status is timed_out' do
    files['hiker.c'] = [
      '#include "hiker.h"',
      'int answer(void) { for(;;); return 6 * 7; }'
    ].join("\n")
    output, _ = assert_run_times_out(files, max_seconds = 2)
    assert_equal '', output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4D7',
  'when run(test-code) does not complete in max_seconds',
  'and does produce output,',
  'the output is nonetheless empty, and',
  'the status is timed_out' do
    files['hiker.c'] = [
      '#include "hiker.h"',
      '#include <stdio.h>',
      'int answer(void) { for(;;) printf("Hello"); return 6 * 7; }'
    ].join("\n")
    output, _ = assert_run_times_out(files, max_seconds = 2)
    assert_equal '', output
  end

end


