require_relative 'externals'
require_relative 'runner'
require 'sinatra/base'
require 'json'

class MicroService < Sinatra::Base

  get '/image_pulled?' do
    getter(__method__)
  end

  post '/image_pull' do
    poster(__method__)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  get  '/kata_exists?' do
    getter(__method__)
  end

  post '/kata_new' do
    poster(__method__)
  end

  post '/kata_old' do
    poster(__method__)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  get  '/avatar_exists?' do
    getter(__method__, avatar_name)
  end

  post '/avatar_new' do
    poster(__method__, avatar_name, starting_files)
  end

  post '/avatar_old' do
    poster(__method__, avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  post '/run' do
    args  = [ avatar_name ]
    args += [ deleted_filenames, changed_files ]
    args += [ max_seconds ]
    poster(__method__, *args)
  end

  private

  def getter(name, *args)
    runner_json( 'GET /', name, *args)
  end

  def poster(name, *args)
    runner_json('POST /', name, *args)
  end

  def runner_json(prefix, caller, *args)
    name = caller.to_s[prefix.length .. -1]
    { name => runner.send(name, *args) }.to_json
  rescue Exception => e
    log << "EXCEPTION: #{e.class.name}.#{caller} #{e.message}"
    { 'exception' => e.message }.to_json
  end

  # - - - - - - - - - - - - - - - -

  include Externals

  def runner
    Runner.new(self, image_name, kata_id)
  end

  def self.request_args(*names)
    names.each { |name|
      define_method name, &lambda { args[name.to_s] }
    }
  end

  request_args :image_name, :kata_id
  request_args :avatar_name, :starting_files
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
