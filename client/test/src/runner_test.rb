
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

require_relative './lib_test_base'
require 'net/http'
require 'json'

class RunnerAppTest < LibTestBase

  def self.hex
    '201BC'
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
    assert_equal success, status
    assert output.start_with?('Assertion failed: answer() == 42'), output
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16F',
  'green-traffic-light' do
    hello
    files['hiker.c'] = files['hiker.c'].sub('6 * 9', '6 * 7')
    do_run(files)
    assert_equal success, status, json
    assert_equal 'All tests passed', output, json
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '295',
  'amber-traffic-light' do
    hello
    files['hiker.c'] = files['hiker.c'].sub('6 * 9', '6 * 9sss')
    do_run(files)
    assert_equal success, status, json
    [
      "invalid suffix \"sss\" on integer constant",
      'return 6 * 9sss'
    ].each do |line|
      assert output.include?(line), json
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

=begin
  # This test passes but kills the runner_server!!!
  # The problems can be seen on the log (after the test has finished)
  #
  # PROBLEM 1
  # ---------
  # runner_server    | 12:59:13 web.1  | "----------------------------------------"
  # runner_server    | 12:59:13 web.1  | "COMMAND:docker volume rm cyber_dojo_201BCE6F_salmon"
  # runner_server    | 12:59:13 web.1  | Error response from daemon: Unable to remove volume,
  #    volume still in use: remove cyber_dojo_201BCE6F_salmon: volume is in use -
  #    [b66474ead6b0720c71a120cde915b20d88c9560a158e4b4f8302fd0d9baf382b]
  #
  # doing [docker ps -a] shows that b6647... is not there/
  # I'm sure this is the child-process [docker rm] again.
  # Note that the runner_server's microservice's goodbye() does not
  # have the synchronization that docker_helpers_test.rb has.
  # Should a run() somehow record the cid inside the volume
  # so the volume can get its cid and do the same synchronization?
  # It seems logical that goodbye on the runner-server should
  # be self-contained.
  #
  # PROBLEM 2
  # ---------
  # runner_server    | 11:50:58 web.1  | "NO-OUTPUT:"
  # runner_server    | 11:50:58 web.1  | "EXITED:137"
  # runner_server    | 11:50:59        | exited with code 0
  # runner_server    | 11:50:59 system | sending SIGTERM to all processes
  # runner_server    | 11:50:59 web.1  | terminated by SIGTERM
  #
  # My guess: this is also related to the pkill in the server's docker_runner.sh
  # - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E6F',
  'timed-out-traffic-light' do
    hello
    files['hiker.c'] = files['hiker.c'].sub('return', 'for(;;); return')
    do_run(files, 3)
    assert_equal timed_out, status, json
    assert_equal '', output
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

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

  def hello
    post(:hello, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def goodbye
    post(:goodbye, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def do_run(changed_files, max_seconds = 10)
    @json = post(:run, {
             image_name:image_name,
                kata_id:kata_id,
            avatar_name:avatar_name,
            max_seconds:max_seconds,
      deleted_filenames:deleted_filenames,
          changed_files:changed_files})
  end

  def json; @json; end
  def status; json['status']; end
  def output; json['output']; end
  def success; 0; end
  def timed_out; 137; end

  def post(method, args)
    uri = URI.parse('http://runner_server:4557/' + method.to_s)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = args.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

end
