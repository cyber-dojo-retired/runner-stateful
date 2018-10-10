require_relative 'http_json_service'

class RunnerService

  def initialize
    @hostname = 'runner-stateful'
    @port = 4557
  end

  def kata_new(image_name, id, starting_files)
    post(__method__, image_name, id, starting_files)
  end

  def kata_old(image_name, id)
    post(__method__, image_name, id)
  end

  # - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(
        image_name, id,
        new_files, deleted_files, unchanged_files, changed_files,
        max_seconds
    )
    args  = [image_name, id]
    args += [new_files, deleted_files, unchanged_files, changed_files ]
    args += [max_seconds]
    post(__method__, *args)
  end

  private

  include HttpJsonService

  attr_reader :hostname, :port

end
