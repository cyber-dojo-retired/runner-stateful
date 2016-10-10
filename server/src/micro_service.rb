
# NB: if you call this file app.rb then SimpleCov fails to see it?!
#     or rather, it botches its appearance in the html view

require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'
require_relative './string_cleaner'

class MicroService < Sinatra::Base

  get '/pulled' do
    content_type :json
    request.body.rewind
    runner.pulled?(image_name)
  end

  post '/pull' do
    content_type :json
    request.body.rewind
    runner.pull(image_name)
  end

  post '/start' do
    content_type :json
    request.body.rewind
    runner.start(kata_id, avatar_name)
  end

  post '/run' do
    content_type :json
    request.body.rewind
    max_seconds = args['max_seconds']
    delete_filenames = args['delete_filenames']
    changed_files = args['changed_files']
    output = runner.run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    cleaned(output)
  end

  private

  include Externals
  include StringCleaner

  def runner
    DockerRunner.new(self)
  end

  def args
    @args ||= JSON.parse(request.body.read)
  end

  def image_name
    args['image_name']
  end

  def kata_id
    args['kata_id']
  end

  def avatar_name
    args['avatar_name']
  end

end


