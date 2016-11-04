require_relative './client_test_base'

class RunTest < ClientTestBase

  def self.hex_prefix; '201BCEF'; end
  def hex_setup; new_avatar; end
  def hex_teardown; old_avatar; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '42D',
  'run with bad arguments sets is non-zero integer error' do
    args = []
    args << image_name
    args << (kata_id = ':') #bad
    args << (avatar_name = ':') #bad
    args << (max_seconds = 10)
    args << (deleted_filenames = [])
    args << (changed_files = {})
    @json = runner.run(*args)
    assert_error
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '348',
  'red-traffic-light' do
    runner_run(files)
    assert_completed
    assert_stdout ''
    assert stderr.start_with?('Assertion failed: answer() == 42'), json.to_s
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16F',
  'green-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 7')
    runner_run(files)
    assert_completed
    assert_stdout "All tests passed\n"
    assert_stderr ''
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '295',
  'amber-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 9sss')
    runner_run(files)
    assert_completed
    assert_stdout ''
    lines = [
      "invalid suffix \"sss\" on integer constant",
      'return 6 * 9sss'
    ]
    lines.each { |line| assert stderr.include?(line), json.to_s }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E6F',
  'timed-out-traffic-light' do
    file_sub('hiker.c', 'return', 'for(;;); return')
    runner_run(files, 3)
    assert_timed_out
    assert_stdout ''
    assert_stderr ''
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'ED4',
  'stdout greater than 10K is truncated' do
    # fold limit is 10000 so I do two smaller folds
    five_K_plus_1 = 5*1024+1
    command = [
      'cat /dev/urandom',
      "tr -dc 'a-zA-Z0-9'",
      "fold -w #{five_K_plus_1}",
      'head -n 1'
    ].join('|')
    runner_run({ 'cyber-dojo.sh' => "seq 2 | xargs -I{} sh -c '#{command}'" })
    assert_completed
    assert stdout.end_with? 'output truncated by cyber-dojo server', json.to_s
    assert_stderr ''
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_completed
    assert_equal completed, status, json.to_s
  end

  def assert_timed_out
    assert_equal timed_out, status, json.to_s
  end

  def assert_error
    assert_equal 'Fixnum', status.class.name, json.to_s
    refute_equal success, status, json.to_s
  end

  def assert_stdout(expected)
    assert_equal expected, stdout, json.to_s
  end

  def assert_stderr(expected)
    assert_equal expected, stderr, json.to_s
  end

end
