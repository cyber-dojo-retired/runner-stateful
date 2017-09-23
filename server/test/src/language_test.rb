require_relative 'test_base'

class LanguageTest < TestBase

  def self.hex_prefix
    '9D930'
  end

  def hex_setup
    kata_setup
  end

  def hex_teardown
    kata_teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '76D',
  '[gcc,assert] runs' do
    sss_run({
      changed_files: files('gcc_assert')
    })
    assert_stderr_include "[makefile:14: test.output] Aborted"
    assert_stderr_include 'Assertion failed: answer() == 42'
    assert_status 2
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '358',
  '[Java,Cucumber] runs' do
    sss_run({
      changed_files: files('java_cucumber')
    })
    assert_stdout_include '1 Scenarios (1 failed)'
    assert_stderr ''
    assert_status 1
  end

end

