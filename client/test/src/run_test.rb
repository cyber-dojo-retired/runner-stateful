require_relative 'client_test_base'

class RunTest < ClientTestBase

  def self.hex_prefix; '201BCEF'; end
  def hex_setup; new_kata; new_avatar; end
  def hex_teardown; old_kata; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '42D',
  'run with invalid kata_id raises kata_id' do
    args = []
    args << image_name
    args << (kata_id = ':') #bad
    args << (avatar_name = 'salmon')
    args << (max_seconds = 10)
    args << (deleted_filenames = [])
    args << (changed_files = {})
    error = assert_raises { runner.run(*args) }
    assert error.message.start_with? 'RunnerService:run:kata_id'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3BA',
  'run with invalid avatar_name raises avatar_name' do
    args = []
    args << image_name
    args << kata_id
    args << (avatar_name = 'lion')
    args << (max_seconds = 10)
    args << (deleted_filenames = [])
    args << (changed_files = {})
    error = assert_raises { runner.run(*args) }
    assert error.message.start_with? 'RunnerService:run:avatar_name'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '348',
  'red-traffic-light' do
    runner_run(files)
    assert_stdout "makefile:14: recipe for target 'test.output' failed\n"
    assert stderr.start_with?('Assertion failed: answer() == 42'), json.to_s
    assert_status 2
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16F',
  'green-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 7')
    runner_run(files)
    assert_stdout "All tests passed\n"
    assert_stderr ''
    assert_status 0
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '295',
  'amber-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 9sss')
    runner_run(files)
    lines = [
      "invalid suffix \"sss\" on integer constant",
      'return 6 * 9sss'
    ]
    lines.each { |line| assert stderr.include?(line), json.to_s }
    assert_stdout "makefile:17: recipe for target 'test' failed\n"
    assert_status 2
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E6F',
  'timed-out-traffic-light' do
    file_sub('hiker.c', 'return', "for(;;);\nreturn")
    runner_run(files, 3)
    assert_stdout ''
    assert_stderr ''
    assert_timed_out
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
    assert stdout.end_with? 'output truncated by cyber-dojo server', json.to_s
    assert_stderr ''
    assert_status 0
  end

end
