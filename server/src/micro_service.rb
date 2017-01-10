require_relative 'externals'
require 'sinatra/base'
require 'json'

class MicroService < Sinatra::Base

  # Some methods have arguments that are unused
  # in particular runner-service implementations.

  get '/pulled?' do
    getter(__method__, image_name)
  end

  post '/pull' do
    poster(__method__, image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  get '/kata_exists?' do
    getter(__method__, image_name, kata_id)
  end

  post '/new_kata' do
    poster(__method__, image_name, kata_id)
  end

  post '/old_kata' do
    poster(__method__, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  get '/avatar_exists?' do
    args = [ image_name, kata_id, avatar_name ]
    getter(__method__, *args)
  end

  post '/new_avatar' do
    args = [ image_name, kata_id, avatar_name ]
    args << starting_files
    poster(__method__, *args)
  end

  post '/old_avatar' do
    args = [ image_name, kata_id, avatar_name ]
    poster(__method__, *args)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  post '/run' do
    args  = [ image_name, kata_id, avatar_name ]
    args += [ deleted_filenames, changed_files ]
    args += [ max_seconds ]
    poster(__method__, *args)
  end

  private

  def getter(name, *args)
    runner_json('GET /', name, *args)
  end

  def poster(name, *args)
    runner_json('POST /', name, *args)
  end

  def runner_json(prefix, caller, *args)
    name = caller.to_s[prefix.length .. -1]
    { name => runner.send(name, *args) }.to_json
  rescue Exception => e
    log << "EXCEPTION: #{e.class.name} #{e.to_s}"
    { 'exception' => e.message }.to_json
  end

  # - - - - - - - - - - - - - - - -

  include Externals

  def self.request_args(*names)
    names.each { |name|
      define_method name, &lambda { args[name.to_s] }
    }
  end

  request_args :image_name
  request_args :kata_id, :avatar_names, :starting_files
  request_args :deleted_filenames, :changed_files
  request_args :max_seconds

  def args
    @args ||= JSON.parse(request_body)
  end

  def request_body
    request.body.rewind
    request.body.read
  end

end
