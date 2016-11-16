require 'sinatra/base'
require 'json'

require_relative './externals'
require_relative './docker_runner'
require_relative './string_cleaner'
require_relative './string_truncater'

class MicroService < Sinatra::Base

  # Some methods have arguments that are unused.
  # They would be used if the runner-service implementation
  # switches from being volume-based to container-based.

  post '/pulled' do
    jasoned(1) { runner.pulled?(image_name) }
  end

  post '/pull' do
    jasoned(0) { runner.pull(image_name) }
  end

  post '/new_kata' do
    jasoned(0) { runner.new_kata(image_name, kata_id) }
  end

  post '/new_avatar' do
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << starting_files
    jasoned(0) { runner.new_avatar(*args) }
  end

  post '/run' do
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << deleted_filenames
    args << changed_files
    args << max_seconds
    jasoned(3) { runner.run(*args) }
  end

  post '/old_avatar' do
    jasoned(0) { runner.old_avatar(kata_id, avatar_name) }
  end

  post '/old_kata' do
    jasoned(0) { runner.old_kata(kata_id) }
  end

  private

  include Externals
  def runner; DockerRunner.new(self); end

  def args; @args ||= request_body_args; end

  def image_name;        args['image_name' ];    end
  def kata_id;           args['kata_id'];        end
  def avatar_name;       args['avatar_name'];    end
  def starting_files;    args['starting_files']; end

  def deleted_filenames; args['deleted_filenames']; end
  def changed_files;     args['changed_files'];     end
  def max_seconds;       args['max_seconds'];       end

  def request_body_args
    request.body.rewind
    JSON.parse(request.body.read)
  end

  include StringCleaner
  include StringTruncater

  def jasoned(n)
    content_type :json
    case n
    when 0
      yield
      return { status:0 }.to_json
    when 1
      return { status:yield }.to_json
    when 3
      stdout,stderr,status = yield
      stdout = truncated(cleaned(stdout))
      stderr = truncated(cleaned(stderr))
      return { stdout:stdout, stderr:stderr, status:status }.to_json
    end
  rescue DockerRunnerError => e
    return { stdout:e.stdout, stderr:e.stderr, status:e.status }.to_json
  rescue StandardError => e
    return { stdout:'', stderr:e.to_s, status:1 }.to_json
  end

end
