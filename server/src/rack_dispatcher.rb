require_relative 'external'
require_relative 'runner'
require_relative 'well_formed_args'
require 'rack'

class RackDispatcher # stateful

  def initialize(cache)
    @cache = cache
  end

  def call(env, request = Rack::Request.new(env))
    external = External.new
    name, args = name_args(request)
    runner = Runner.new(external, @cache)
    triple({ name => runner.public_send(name, *args) })
  rescue => error
    #puts error.backtrace
    triple({ 'exception' => error.message })
  end

  private # = = = = = = = = = = = =

  def name_args(request)
    name = request.path_info[1..-1] # lose leading /
    @well_formed_args = WellFormedArgs.new(request.body.read)
    args = case name
      when /^sha$/          then []
      when /^kata_new$/     then [image_name, kata_id, starting_files]
      when /^kata_old$/     then [image_name, kata_id]
      when /^run_cyber_dojo_sh$/
        [image_name, kata_id,
         new_files, deleted_files, unchanged_files, changed_files,
         max_seconds]
      else
        raise ArgumentError, 'json:malformed'
    end
    [name, args]
  end

  # - - - - - - - - - - - - - - - -

  def triple(body)
    [ 200, { 'Content-Type' => 'application/json' }, [ body.to_json ] ]
  end

  # - - - - - - - - - - - - - - - -

  def self.well_formed_args(*names)
      names.each do |name|
        define_method name, &lambda { @well_formed_args.send(name) }
      end
  end

  well_formed_args :image_name,
                   :kata_id,
                   :starting_files,
                   :new_files,
                   :deleted_files,
                   :unchanged_files,
                   :changed_files,
                   :max_seconds
end
