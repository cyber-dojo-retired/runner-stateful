require 'json'
require 'net/http'

module Runner # mix-in

  module_function

  def run #(was_files, now_files)
    uri = URI.parse('http://runner_server:4557/run')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = {
      :delete_filenames => [],
      :changed_files => {},
      :image_name => 'cyberdojofoundation/gcc_assert',
      :max_seconds => 10
    }.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

end


