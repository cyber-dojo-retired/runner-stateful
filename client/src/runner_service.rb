require_relative 'http_json_service'

class RunnerService

  def image_pulled?(image_name, kata_id)
    get(__method__, image_name, kata_id)
  end

  def image_pull(image_name, kata_id)
    post(__method__, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - -

  def kata_exists?(image_name, kata_id)
    get(__method__, image_name, kata_id)
  end

  def kata_new(image_name, kata_id)
    post(__method__, image_name, kata_id)
  end

  def kata_old(image_name, kata_id)
    post(__method__, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(image_name, kata_id, avatar_name)
    get(__method__, image_name, kata_id, avatar_name)
  end

  def avatar_new(image_name, kata_id, avatar_name, starting_files)
    post(__method__, image_name, kata_id, avatar_name, starting_files)
  end

  def avatar_old(image_name, kata_id, avatar_name)
    post(__method__, image_name, kata_id, avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - -

=begin
  def run_cyber_dojo_sh(
        image_name, kata_id, avatar_name,
        deleted_files, unchanged_files, changed_files, new_files,
        max_seconds
    )
    args = [image_name, kata_id, avatar_name]
    args += [deleted_files, unchanged_files, changed_files, new_files]
    args += [max_seconds]
    post(__method__, *args)
  end
=end

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << deleted_filenames
    args << changed_files
    args << max_seconds
    post(__method__, *args)
  end

  private

  include HttpJsonService

  def hostname
    ENV['CYBER_DOJO_RUNNER_SERVER_NAME']
  end

  def port
    ENV['CYBER_DOJO_RUNNER_SERVER_PORT']
  end

end
