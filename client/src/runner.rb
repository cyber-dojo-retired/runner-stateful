require 'json'
require 'net/http'

module Runner # mix-in

  module_function

  def pulled?(image_name)
    # TODO get
  end

  def pull(image_name)
    # TODO post
  end

  def start(kata_id, avatar_name)
    # TODO post
  end

  def run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    uri = URI.parse('http://runner_server:4557/run')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = {
      :image_name => image_name,
      :kata_id => kata_id,
      :avatar_name => avatar_name,
      :max_seconds => max_seconds,
      :delete_filenames => delete_filenames,
      :changed_files => changed_files
    }.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

end


