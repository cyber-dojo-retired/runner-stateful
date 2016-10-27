
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
  'smoke-test' do
    assert_equal 1, 1
  end

  private

  def kata_id; 'D4C8A65D61'; end
  def avatar_name; 'salmon'; end

  def hello(kata_id, avatar_name)
    post(:hello, { kata_id:kata_id, avatar_name:avatar_name })
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
