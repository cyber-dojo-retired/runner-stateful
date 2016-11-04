require 'json'
require 'net/http'

class RunnerPostAdapter

  def pull_image(image_name)
    post(__method__, { image_name:image_name })
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def new_kata(kata_id, image_name)
    post(__method__, { kata_id:kata_id, image_name:image_name })
  end

  def old_kata(kata_id)
    post(__method__, { kata_id:kata_id })
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(kata_id, avatar_name)
    post(__method__, { kata_id:kata_id, avatar_name:avatar_name })
  end

  def old_avatar(kata_id, avatar_name)
    post(__method__, { kata_id:kata_id, avatar_name:avatar_name })
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    post(__method__, {
                 image_name:image_name,
                    kata_id:kata_id,
                avatar_name:avatar_name,
                max_seconds:max_seconds,
          deleted_filenames:deleted_filenames,
              changed_files:changed_files
    })
  end

  private

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


