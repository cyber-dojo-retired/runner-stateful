
# NB: if you call this file app_test.rb then SimpleCov fails to see it?!

require_relative './lib_test_base'
require 'net/http'

class RunnerAppTest < LibTestBase

  def self.hex
    '201'
  end

  test '348',
  'start returns volume-name and exit_code' do
    kata_id = 'D4C8A65D61'
    avatar_name = 'lion'
    json = start(kata_id, avatar_name)
    puts JSON.pretty_unparse(json)
    sdsd
    assert_equal "cyber_dojo_#{kata_id}_#{avatar_name}", output
    assert_equal success, exit_status
  end

  private

  def start(kata_id, avatar_name)
    post(:start, { :kata_id     => kata_id,
                   :avatar_name => avatar_name})
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
