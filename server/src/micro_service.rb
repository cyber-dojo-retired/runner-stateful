require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'

class MicroService < Sinatra::Base

  # Some methods have arguments that are unused.
  # They would be used if the runner-service implementation
  # switches from being volume-based to container-based.

  get '/pulled' do
    getter(__method__, image_name)
  end

  post '/pull' do
    poster(__method__, image_name)
  end

  post '/new_kata' do
    poster(__method__, image_name, kata_id)
  end

  post '/new_avatar' do
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << starting_files
    poster(__method__, *args)
  end

  post '/run' do
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << deleted_filenames
    args << changed_files
    args << max_seconds
    poster(__method__, *args)
  end

  post '/old_avatar' do
    poster(__method__, kata_id, avatar_name)
  end

  post '/old_kata' do
    poster(__method__, kata_id)
  end

  private

  def getter(name, *args)
    storer_json('GET /', name, *args)
  end

  def poster(name, *args)
    storer_json('POST /', name, *args)
  end

  def storer_json(prefix, caller, *args)
    name = caller.to_s[prefix.length .. -1]
    runner = DockerRunner.new(self)
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

  request_args :image_name, :kata_id, :avatar_name
  request_args :starting_files
  request_args :deleted_filenames
  request_args :changed_files
  request_args :max_seconds

  def args
    @args ||= JSON.parse(request_body)
  end

  def request_body
    request.body.rewind
    request.body.read
  end

end
