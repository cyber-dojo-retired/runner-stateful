require_relative 'http_json_service'

class RunnerService

  def initialize
    @hostname = ENV['RUNNER_STATEFUL_SERVICE_NAME']
    @port = ENV['RUNNER_STATEFUL_SERVICE_PORT'].to_i
  end

  def kata_new(image_name, kata_id, starting_files)
    post(__method__, image_name, kata_id, starting_files)
  end

  def kata_old(image_name, kata_id)
    post(__method__, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(
        image_name, kata_id,
        new_files, deleted_files, unchanged_files, changed_files,
        max_seconds
    )
    args  = [image_name, kata_id]
    args += [new_files, deleted_files, unchanged_files, changed_files ]
    args += [max_seconds]
    post(__method__, *args)
  end

  private

  include HttpJsonService

  attr_reader :hostname, :port

end
