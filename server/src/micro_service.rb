require 'benchmark'
require 'prometheus/client/push'

require_relative 'externals'
require_relative 'runner'
require 'sinatra/base'
require 'json'


class MicroService < Sinatra::Base

  def self.prom(prometheus)
    @@prometheus = prometheus
    @@run = @@prometheus.histogram(:run, 'seconds')
  end

  # Some methods have arguments that are unused
  # in particular runner-service implementations.

  get '/kata_exists?' do
    getter(__method__)
  end

  post '/new_kata' do
    poster(__method__)
  end

  post '/old_kata' do
    poster(__method__)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  get '/avatar_exists?' do
    getter(__method__, avatar_name)
  end

  post '/new_avatar' do
    poster(__method__, avatar_name, starting_files)
  end

  post '/old_avatar' do
    poster(__method__, avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  post '/run' do
    args  = [ avatar_name ]
    args += [ deleted_filenames, changed_files ]
    args += [ max_seconds ]

    json = nil
    duration = Benchmark.realtime {
      json = poster(__method__, *args)
    }

    @@run.observe({ image_name: runner.image_name }, duration)
    gateway = 'http://prometheus_pushgateway:9091'
    job_name = 'runner'
    Prometheus::Client::Push.new(job_name, instance=nil, gateway).add(@@prometheus)

    json
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
    log << "EXCEPTION: #{e.class.name}.#{caller} #{e.message}"
    { 'exception' => e.message }.to_json
  end

  # - - - - - - - - - - - - - - - -

  include Externals
  include Runner

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
