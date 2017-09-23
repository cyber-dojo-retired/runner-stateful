require_relative 'test_base'
require_relative 'os_helper'

class ForkBombTest < TestBase

  include OsHelper

  def self.hex_prefix
    '35758'
  end

  def hex_setup
    kata_setup
  end

  def hex_teardown
    kata_teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CD5',
  %w( [Alpine] fork-bomb in C fails to go off ) do
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
    as_avatar('lion') {
      sss_run({
          avatar_name:'lion',
        changed_files:{'hiker.c' => hiker_c }
      })
      assert_equal '', stderr
      lines = stdout.split("\n")
      assert lines.count{ |line| line == 'All tests passed' } > 42
      assert lines.count{ |line| line == 'fork() => 0'  } > 42
      assert lines.count{ |line| line == 'fork() => -1' } > 42
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4DE',
  %w( [Alpine] fork-bomb in shell fails to go off ) do
    # The fork-bomb fails in a non-deterministic way.
    # Occasionally, it throws an ArgumentError exception.
    # The nocov markers around the block keep coverage at 100%
    @log = LoggerSpy.new(nil)
    cyber_dojo_sh = 'bomb() { bomb | bomb & }; bomb'
    as_avatar('lion') {
      # :nocov:
      begin
        sss_run({
            avatar_name:'lion',
          changed_files:{'cyber-dojo.sh' => cyber_dojo_sh }
        })
        assert_equal success, status
        assert_equal '', stdout
        assert stderr.include? "./cyber-dojo.sh: line 1: can't fork"
      rescue ArgumentError
        rag_filename = '/usr/local/bin/red_amber_green.rb'
        cmd = "'cat #{rag_filename}'"
        assert /COMMAND:docker .* sh -c #{cmd}/.match @log.spied[1]
        assert_equal 'STATUS:2',                      @log.spied[2]
        assert_equal 'STDOUT:',                       @log.spied[3]
        assert_equal "STDERR:sh: can't fork\n",       @log.spied[4]
      end
      # :nocov:
    }
  end

end
