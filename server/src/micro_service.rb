
# NB: if you call this file app.rb then SimpleCov fails to see it?!
#     or rather, it botches its appearance in the html view

require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'
#require_relative './string_cleaner'

class MicroService < Sinatra::Base

  get '/pulled' do
    content_type :json
    runner.pulled?(image_name)
  end

  post '/pull' do
    content_type :json
    runner.pull(image_name)
  end

  post '/start' do
    content_type :json
    output, status = runner.start(kata_id, avatar_name)
    { status:status, output:output }.to_json
  end

  post '/run' do
    content_type :json
    max_seconds = args['max_seconds']
    delete_filenames = args['delete_filenames']
    changed_files = args['changed_files']
    output, status = runner.run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    { exit:status, output:output }.to_json
  end

  private

  include Externals
  #include StringCleaner

  def runner
    DockerRunner.new(self)
  end

  def args
    @args ||= request_body_args
  end

  def request_body_args
    request.body.rewind
    JSON.parse(request.body.read)
  end

  def image_name;  args['image_name' ]; end
  def kata_id;     args['kata_id'    ]; end
  def avatar_name; args['avatar_name']; end

end


