
# NB: if you call this file app.rb then SimpleCov fails to see it?!
#     or rather, it botches its appearance in the html view

require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './runner'
require_relative './starter'
require_relative './string_cleaner'

class MicroService < Sinatra::Base

  get '/start' do
    content_type :json
    request.body.rewind
    args = JSON.parse(request.body.read)
    id = args['id']
    avatar = args['avatar']
    start(id, avatar)
  end

  get '/run' do
    content_type :json
    request.body.rewind
    args = JSON.parse(request.body.read)
    delete_filenames = args['delete_filenames']
    changed_files = args['changed_files']
    image_name = args['image_name']
    max_seconds = args['max_seconds']
    output = run(delete_filenames, changed_files, image_name, max_seconds)
    cleaned(output)
  end

  private

  include Externals
  include Runner
  include Starter
  include StringCleaner

end


