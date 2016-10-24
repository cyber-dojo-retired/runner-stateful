
# NB: if you call this file app.rb then SimpleCov fails to see it?!
#     or rather, it botches its appearance in the html view

require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'

class MicroService < Sinatra::Base

  get '/pulled' do
    jasoned *runner.pulled?(image_name)
  end

  post '/pull' do
    jasoned *runner.pull(image_name)
  end

  post '/start' do
    jasoned *runner.start(kata_id, avatar_name)
  end

  post '/run' do
    cid = runner.create_container(image_name, kata_id, avatar_name)
    runner.deleted_files(cid, deleted_filenames)
    runner.changed_files(cid, changed_files)
    runner.setup_home(cid, image_name)
    jasoned *runner.run(cid, max_seconds)
  end

  private

  include Externals

  def runner; DockerRunner.new(self); end
  def args; @args ||= request_body_args; end

  def request_body_args
    request.body.rewind
    JSON.parse(request.body.read)
  end

  def image_name;        args['image_name' ];      end
  def kata_id;           args['kata_id'    ];      end
  def avatar_name;       args['avatar_name'];      end
  def max_seconds;       args['max_seconds'];      end
  def deleted_filenames; args['deleted_filenames']; end
  def changed_files;     args['changed_files'];    end

  def jasoned(output, status)
    content_type :json
    { status:status, output:output.strip }.to_json
  end

end


