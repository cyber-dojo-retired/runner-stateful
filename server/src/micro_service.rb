require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'

class MicroService < Sinatra::Base

  get '/pulled_image' do; jasoned *runner.pulled_image?(image_name); end
  post '/pull_image'  do; jasoned2 { runner.pull_image(image_name) }; end

  post '/new_avatar'  do; jasoned2 { runner.new_avatar(kata_id, avatar_name) }; end
  post '/old_avatar'  do; jasoned *runner.old_avatar(kata_id, avatar_name); end

  post '/run' do
    status, stdout, stderr = runner.run(
      image_name,
      kata_id, avatar_name,
      max_seconds,
      deleted_filenames, changed_files
    )
    content_type :json
    { status:status, stdout:stdout, stderr:stderr }.to_json
  end

  private

  include Externals
  def runner; DockerRunner.new(self); end

  def args; @args ||= request_body_args; end
  def image_name;        args['image_name' ];      end
  def kata_id;           args['kata_id'    ];      end
  def avatar_name;       args['avatar_name'];      end
  def max_seconds;       args['max_seconds'];      end
  def deleted_filenames; args['deleted_filenames']; end
  def changed_files;     args['changed_files'];    end
  def request_body_args
    request.body.rewind
    JSON.parse(request.body.read)
  end

  def jasoned2
    content_type :json
    begin
      output, status = yield
    rescue RuntimeError => e
      output, status = e.to_s, 'error'
    end
    { status:status, output:output }.to_json
  end

  def jasoned(output, status)
    content_type :json
    { status:status, output:output }.to_json
  end

end


