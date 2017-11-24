require_relative 'test_base'
require_relative 'logger_spy'
require_relative '../../src/logger_stdout'

class ShellBasherTest < TestBase

  def self.hex_prefix
    'C89'
  end

  # - - - - - - - - - - - - - - - - -
  # shell.exec(cmd)
  # - - - - - - - - - - - - - - - - -

  test '243', %w( when exec(cmd) raises the exception is logged ) do
    @logged = with_captured_stdout {
      assert_raises(StandardError) {
        shell.exec('xxx Hello')
      }
    }
    assert_logged(
      line,
      'COMMAND:xxx Hello',
      'RAISED-CLASS:Errno::ENOENT', # DROP?
      'RAISED-TO_S:No such file or directory - xxx'
     #'MESSAGE:No such file or directory - xxx'
    )
  end

  # - - - - - - - - - - - - - - - - -

  test '244',
  %w( when exec(cmd) is zero,
      it return [stdout,stderr,status]
      and does not log ) do
    @logged = with_captured_stdout {
      stdout,stderr,status = shell.exec('printf Hello')
      assert_equal 'Hello', stdout
      assert_equal '', stderr
      assert_equal 0, status
    }
    assert_nothing_logged
  end

  # - - - - - - - - - - - - - - - - -

  test '245',
  %w( when exec(cmd) is non-zero,
      it returns [stdout,stderr,status]
      and logs ) do
    @logged = with_captured_stdout {
      stdout,stderr,status = shell.exec('printf Bye && false')
      assert_equal 'Bye', stdout
      assert_equal '', stderr
      assert_equal 1, status
    }
    assert_logged(
      line,
      'COMMAND:printf Bye && false',
      'STATUS:1',
      'STDOUT:Bye',
      'STDERR:'
    )
  end

  # - - - - - - - - - - - - - - - - -
  # shell.assert(cmd)
  # - - - - - - - - - - - - - - - - -

  test '246',
  %w( when assert(cmd) raises the exception is logged ) do
    @logged = with_captured_stdout {
      assert_raises(StandardError) {
        shell.assert('xxx Hello')
      }
    }
    assert_logged(
      line,
      'COMMAND:xxx Hello',
      'RAISED-CLASS:Errno::ENOENT', # DROP?
      'RAISED-TO_S:No such file or directory - xxx'
     #'MESSAGE:No such file or directory - xxx'
    )
  end

  # - - - - - - - - - - - - - - - - -

  test '247',
  %w( when assert(cmd) is zero
      nothing is logged,
      stdout is returned ) do
    @logged = with_captured_stdout {
      stdout = shell.assert('printf Hello')
      assert_equal 'Hello', stdout
    }
    assert_nothing_logged
  end

  # - - - - - - - - - - - - - - - - -

  test '248',
  %w( when assert(cmd) is non-zero,
      exception is raised,
      command and stdout,stderr,status is logged ) do
    @logged = with_captured_stdout {
      error = assert_raises(StandardError) {
        shell.assert('printf Hello && false')
      }
      assert_equal 'command:printf Hello && false', error.message
    }
    assert_logged(
      line,
      'COMMAND:printf Hello && false',
      'STATUS:1',
      'STDOUT:Hello',
      'STDERR:'
    )
  end

  # - - - - - - - - - - - - - - - - -

  def assert_nothing_logged
    assert_logged()
  end

  def assert_logged(*lines)
    lines = lines.map { |line| quoted(line) }
    if lines == []
      assert_equal '', @logged
    else
      assert_equal(lines.join("\n") + "\n", @logged)
    end
  end

  def quoted(s)
    '"' + s + '"'
  end

  def line
    '-' * 40
  end

end
