require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'

class MicroService < Sinatra::Base

  get '/pulled_image' do; jasoned2 { runner.pulled_image?(image_name) }; end
  post '/pull_image'  do; jasoned2 { runner.pull_image(image_name) }; end

  post '/new_avatar'  do; jasoned2 { runner.new_avatar(kata_id, avatar_name) }; end
  post '/old_avatar'  do; jasoned2 { runner.old_avatar(kata_id, avatar_name) }; end

  post '/run' do
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << max_seconds
    args << deleted_filenames
    args << changed_files
    jasoned3 { runner.run(*args) }
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

  def jasoned3
    content_type :json
    begin
      status, stdout, stderr = yield
    rescue RuntimeError => e
      status, stdout, stderr = 'error', '', e.to_s
    end
    { status:status, stdout:stdout, stderr:stderr }.to_json
  end

end


