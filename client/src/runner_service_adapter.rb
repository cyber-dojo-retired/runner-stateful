require 'json'
require 'net/http'

class RunnerServiceAdapter

  def pulled?(image_name)
    get(:pulled, { image_name:image_name })
  end

  def pull(image_name)
    post(:pull, { image_name:image_name })
  end

  def hello(kata_id, avatar_name)
    post(:hello, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def execute(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    post(:execute, {
                 image_name:image_name,
                    kata_id:kata_id,
                avatar_name:avatar_name,
                max_seconds:max_seconds,
          deleted_filenames:deleted_filenames,
              changed_files:changed_files
    })
  end

  def goodbye(kata_id, avatar_name)
    post(:goodbye, { kata_id:kata_id, avatar_name:avatar_name })
  end

  private

  def post(method, args)
    net_http(method, args) { |uri| Net::HTTP::Post.new(uri) }
  end

  def get(method, args)
    net_http(method, args) { |uri| Net::HTTP::Get.new(uri) }
  end

  def net_http(method, args)
    uri = URI.parse('http://runner_server:4557/' + method.to_s)
    http = Net::HTTP.new(uri.host, uri.port)
    request = yield uri.request_uri
    request.content_type = 'application/json'
    request.body = args.to_json
    response = http.request(request)
    JSON.parse(response.body)
  end

end


