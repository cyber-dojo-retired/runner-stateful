require_relative './client_test_base'
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

class RunnerAppTest < ClientTestBase

  def self.hex_prefix; '201BCEF'; end
  def hex_setup; new_avatar; end
  def hex_teardown; old_avatar; end

  test 'C7A',
  'pulled_image? status is true if image has been pulled' do
    pulled_image?('cyberdojofoundation/gcc_assert')
    assert_equal true, status
    assert_equal '', json['output'], json
  end

  test 'F43',
  'pulled_image? status is false if image has not been pulled' do
    pulled_image?('cyberdojofoundation/does_not_exist')
    assert_equal false, status
    assert_equal '', json['output'], json
  end

  test '92F',
  'pulled_image? with illegal image_name returns false' do
    pulled_image?('123/456')
    assert_equal false, status
    assert_equal '', json['output'], json
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '4CE',
  'pull_image status is zero if pull succeeds' do
    pull_image('cyberdojofoundation/gcc_assert')
    assert_equal 0, status
    assert json['output'].include?('Pulling from cyberdojofoundation/gcc_assert'), json
  end

  #test 'F30',
  #'pull_image with illegal image_name returns XXXX' do
  #  pull_image('123/456')
  #  assert_equal 0, status
  #  assert json['output'].include?('Pulling from cyberdojofoundation/gcc_assert'), json
  #end

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
