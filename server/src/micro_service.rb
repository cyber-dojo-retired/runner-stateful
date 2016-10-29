require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'

class MicroService < Sinatra::Base

  get '/pulled' do; jasoned *runner.pulled?(image_name); end
  post '/pull'  do; jasoned *runner.pull(image_name); end

  post '/hello'   do; jasoned *runner.hello(kata_id, avatar_name); end
  post '/goodbye' do; jasoned *runner.goodbye(kata_id, avatar_name); end

  post '/run' do
    jasoned *runner.run(
      image_name,
      kata_id, avatar_name,
      max_seconds,
      deleted_filenames, changed_files)
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

  def jasoned(output, status)
    content_type :json
    { status:status, output:output }.to_json
  end

end


