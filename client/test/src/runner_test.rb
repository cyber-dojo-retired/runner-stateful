
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

require_relative './lib_test_base'
require 'net/http'
require 'json'

class RunnerAppTest < LibTestBase

  def self.hex
    '201'
  end

  def external_setup
    hello(kata_id, avatar_name)
  end

  def external_teardown
    goodbye(kata_id, avatar_name)
  end

  test '348',
  'red-traffic-light' do
    image_name = 'cyberdojofoundation/gcc_assert'
    max_seconds = 10
    deleted_filenames = []
    changed_files = {
      'hiker.c'       => read('hiker.c'),
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    json = do_run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    assert_equal 0, json['status']
    assert json['output'].start_with?('Assertion failed: answer() == 42')
  end

  private

  def kata_id; 'D4C8A65D61'; end
  def avatar_name; 'salmon'; end

  def read(filename)
    IO.read("/app/start_files/gcc_assert/#{filename}")
  end

  def hello(kata_id, avatar_name)
    post(:hello, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def do_run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    post(:run, { image_name:image_name,
                    kata_id:kata_id,
                avatar_name:avatar_name,
                max_seconds:max_seconds,
          deleted_filenames:deleted_filenames,
              changed_files:changed_files})
  end

  def goodbye(kata_id, avatar_name)
    post(:goodbye, { kata_id:kata_id, avatar_name:avatar_name })
  end

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
