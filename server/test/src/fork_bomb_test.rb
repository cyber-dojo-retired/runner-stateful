require_relative 'test_base'
require_relative 'os_helper'

class ForkBombTest < TestBase

  include OsHelper

  def self.hex_prefix; '35758'; end

  def hex_setup; kata_setup; end
  def hex_teardown; kata_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CD5', %w( [Alpine]
  fork-bomb in C fails to go off
  ) do
    avatar_new('lion')
    hiker_c = [
      '#include "hiker.h"',
      '#include <stdio.h>',
      '#include <unistd.h>',
      '',
      'int answer(void)',
      '{',
      '    for(;;)',
      '    {',
      '        int pid = fork();',
      '        fprintf(stdout, "fork() => %d\n", pid);',
      '        fflush(stdout);',
      '        if (pid == -1)',
      '            break;',
      '    }',
      '    return 6 * 7;',
      '}'
    ].join("\n")
    begin
      sss_run({ avatar_name:'lion', changed_files:{'hiker.c' => hiker_c }})
      assert_equal '', stderr
      lines = stdout.split("\n")
      assert lines.count{ |line| line == 'All tests passed' } > 42
      assert lines.count{ |line| line == 'fork() => 0' } > 42
      assert lines.count{ |line| line == 'fork() => -1' } > 42
    ensure
      avatar_old('lion')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4DE', %w( [Alpine]
  fork-bomb in shell fails to go off
  ) do
    avatar_new('lion')
    cyber_dojo_sh = 'bomb() { bomb | bomb & }; bomb'
    begin
      sss_run({ avatar_name:'lion', changed_files:{'cyber-dojo.sh' => cyber_dojo_sh }})
      assert_equal success, status
      assert_equal '', stdout
      assert stderr.include? "./cyber-dojo.sh: line 1: can't fork"
    ensure
      avatar_old('lion')
    end
  end

end
