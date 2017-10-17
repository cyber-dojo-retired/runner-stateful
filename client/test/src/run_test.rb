require_relative 'test_base'

class RunTest < TestBase

  def self.hex_prefix
    '201BCEF'
  end

  def hex_setup
    kata_new
    avatar_new
  end

  def hex_teardown
    avatar_old
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D5F',
  'run with invalid image_name raises' do
    error = assert_raises { run4({ image_name:Object.new }) }
    assert_equal 'RunnerService:run:image_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '42D',
  'run with invalid kata_id raises' do
    error = assert_raises { run4({ kata_id:Object.new }) }
    assert_equal 'RunnerService:run:kata_id:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '3BA',
  'run with invalid avatar_name raises avatar_name' do
    error = assert_raises { run4({ avatar_name:'rod_father' }) }
    assert_equal 'RunnerService:run:avatar_name:invalid', error.message
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test cases
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '348',
  'red-traffic-light' do
    run4
    assert_colour 'red'
    lines = [
      'Assertion failed: answer() == 42',
      "make: *** [makefile:14: test.output] Aborted"
    ]
    lines.each { |line| assert_stderr_include(line) }
    assert_status 2
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16F',
  'green-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 7')
    run4
    assert_colour 'green'
    assert_stdout "All tests passed\n"
    assert_stderr ''
    assert_status 0
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '295',
  'amber-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 9sss')
    run4
    assert_colour 'amber'
    lines = [
      "invalid suffix \"sss\" on integer constant",
      'return 6 * 9sss'
    ]
    lines.each { |line| assert_stderr_include(line) }
    assert_status 2
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E6F',
  'timed-out-traffic-light' do
    file_sub('hiker.c', 'return', "for(;;);\nreturn")
    run4({ max_seconds:3 })
    assert_colour timed_out
    assert_stdout ''
    assert_stderr ''
    assert_status 137
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '722',
  'code with extra 500K file is red' do
    run4({
      changed_files:{ 'large.txt' => 'X'*1023*500 },
      image_name:"#{cdf}/gcc_assert"
    })
    assert_colour 'red'
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
    run4({
      changed_files: {
        'cyber-dojo.sh': "seq 2 | xargs -I{} sh -c '#{command}'"
      }
    })
    assert_stdout_include 'output truncated by cyber-dojo'
    assert_stderr ''
    assert_status 0
  end

end
