require_relative './lib_test_base'
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

class RunnerAppTest < LibTestBase

  def self.hex
    '201BCEF'
  end

  def external_setup
    # can't do hello in setup because test_id not yet set
  end

  def external_teardown
    goodbye
  end

  test '348',
  'red-traffic-light' do
    hello
    do_run(files)
    assert_equal completed, status
    assert output.start_with?('Assertion failed: answer() == 42'), output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16F',
  'green-traffic-light' do
    hello
    files['hiker.c'] = files['hiker.c'].sub('6 * 9', '6 * 7')
    do_run(files)
    assert_equal completed, status, json
    assert_equal "All tests passed\n", output, json
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '295',
  'amber-traffic-light' do
    hello
    files['hiker.c'] = files['hiker.c'].sub('6 * 9', '6 * 9sss')
    do_run(files)
    assert_equal completed, status, json
    lines = [
      "invalid suffix \"sss\" on integer constant",
      'return 6 * 9sss'
    ]
    lines.each { |line| assert output.include?(line), json }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E6F',
  'timed-out-traffic-light' do
    hello
    files['hiker.c'] = files['hiker.c'].sub('return', 'for(;;); return')
    do_run(files, 3)
    assert_equal timed_out, status, json
    assert_equal '', output
  end

  private

  def hello
    @json = runner.hello(kata_id, avatar_name)
  end

  def goodbye
    @json = runner.goodbye(kata_id, avatar_name)
  end

  def do_run(changed_files, max_seconds = 10)
    @json = runner.run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
  end

  def runner
    @runner ||= RunnerServiceAdapter.new
  end

  def json; @json; end
  def status; json['status']; end
  def output; json['output']; end

  def image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; test_id; end
  def avatar_name; 'salmon'; end
  def deleted_filenames; []; end

  def files; @files ||= read_files; end
  def read_files
    filenames =%w( hiker.c hiker.h hiker.tests.c cyber-dojo.sh makefile )
    Hash[filenames.collect { |filename|
      [filename, IO.read("/app/start_files/gcc_assert/#{filename}")]
    }]
  end

  def completed;   0; end
  def timed_out; 128; end

end
