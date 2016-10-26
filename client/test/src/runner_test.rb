
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

require_relative './lib_test_base'
require 'net/http'

class RunnerAppTest < LibTestBase

  def self.hex
    '201'
  end

  def external_setup
    hello_avatar(kata_id, avatar_name)
  end

  def external_teardown
    goodbye_avatar(kata_id, avatar_name)
  end

  test '348',
  'smoke-test' do
    ...
  end

  private

  def kata_id; 'D4C8A65D61'; end
  def avatar_name; 'salmon'; end

  def hello_avatar(kata_id, avatar_name)
    post(:hello_avatar, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def goodbye_avatar(kata_id, avatar_name)
    post(:goodbye_avatar, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def post(method, args)
    uri = URI.parse('http://runner_server:4557/' + method.to_s)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = args.to_json
    response = http.request(request)
    response.body
  end

end
