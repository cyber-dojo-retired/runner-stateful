require_relative './client_test_base'

class RunTest < ClientTestBase

  def self.hex_prefix; '201BCEF'; end
  def hex_setup; new_avatar; end
  def hex_teardown; old_avatar; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '348',
  'red-traffic-light' do
    runner_run(files)
    assert_equal completed, status
    assert stderr.start_with?('Assertion failed: answer() == 42'), json
    assert_equal '', stdout, json
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16F',
  'green-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 7')
    runner_run(files)
    assert_equal completed, status, json
    assert_equal "All tests passed\n", stdout, json
    assert_equal '', stderr, json
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '295',
  'amber-traffic-light' do
    file_sub('hiker.c', '6 * 9', '6 * 9sss')
    runner_run(files)
    assert_equal completed, status, json
    lines = [
      "invalid suffix \"sss\" on integer constant",
      'return 6 * 9sss'
    ]
    lines.each { |line| assert stderr.include?(line), json }
    assert_equal '', stdout, json
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E6F',
  'timed-out-traffic-light' do
    file_sub('hiker.c', 'return', 'for(;;); return')
    runner_run(files, 3)
    assert_equal timed_out, status, json
    assert_equal '', stdout, json
    assert_equal '', stderr, json
  end

end
