
require_relative './nearest_ancestors'
require_relative './runner'

class DockerRunner

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def pull(image_name)
    exec("docker pull #{image_name}")
  end

  def start(kata_id, avatar_name)
    name = "cyber_dojo_#{kata_id}_#{avatar_name}"
    exec("docker volume create --name #{name}")
  end

  def run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    # TODO: what if filename has a quote in it?
    vol_name = "cyber_dojo_#{kata_id}_#{avatar_name}"
    cid = create_container_with_volume_mounted_as_sandbox(vol_name, image_name)
    delete_deleted_files_from_sandbox(cid, delete_filenames)
    copy_changed_files_into_sandbox(cid, changed_files)
    ensure_user_nobody_owns_changed_files(cid)
    ensure_user_nobody_has_HOME(cid)
    output, exit_status = runner_sh(cid, max_seconds)
    output_or_timed_out(output, exit_status, max_seconds)
  end

  private

  include NearestAncestors
  include Runner

  def image_names
    output, _ = exec('docker images')
    # This will (harmlessly) get all cyberdojofoundation image names too.
    lines = output.split("\n").select { |line| line.start_with?('cyberdojo') }
    lines.collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def create_container_with_volume_mounted_as_sandbox(vol_name, image_name)
    # Assume volume exists from previous /start
    # F#-NUnit cyber-dojo.sh actually names the /sandbox folder
    command = [
      'docker run',
      '--detach',                          # get the cid
      '--interactive',                     # exec later ?NECESSARY?
      '--net=none',                        # security
      '--pids-limit=64',                   # security (fork bombs)
      '--security-opt=no-new-privileges',  # security
      '--user=root',                       # TODO: NECESSARY?
      "--volume=#{vol_name}:/sandbox",
      "#{image_name} sh"
    ].join(space = ' ')
    output, _ = exec(command)
    cid = output.strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_deleted_files_from_sandbox(cid, filenames)
    filenames.each do |filename|
      exec("docker exec #{cid} sh -c 'rm /sandbox/#{filename}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def copy_changed_files_into_sandbox(cid, changed_files)
    Dir.mktmpdir('runner') do |tmp_dir|
      changed_files.each do |filename, content|
        pathed_filename = tmp_dir + '/' + filename
        disk.write(pathed_filename, content)
        exec("chmod +x #{pathed_filename}") if pathed_filename.end_with?('.sh')
      end
      exec("docker cp #{tmp_dir}/. #{cid}:/sandbox")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ensure_user_nobody_owns_changed_files(cid)
    exec("docker exec #{cid} sh -c 'chown -R nobody /sandbox'")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ensure_user_nobody_has_HOME(cid)
    # TODO: execute this command only for C#-NUnit image_name???
    # The existing C#-NUnit image picks up HOME from the *current* user.
    # By default, nobody's entry in /etc/passwd is
    #       nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
    # and nobody does not have a home dir.
    # I usermod to solve this. The C#-NUnit docker image is built
    # from an Ubuntu base which has usermod.
    # Of course, the usermod runs if you are not using C#-NUnit too.
    # In particular usermod is _not_ installed in a default Alpine linux.
    # It's in the shadow package.
    exec("docker exec #{cid} sh -c 'usermod --home /sandbox nobody 2> /dev/null'")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner_sh(cid, max_seconds)
    #comment [docker rm -f cid] in docker_runner.sh if you want to shell into cid
    #p cid
    output, exit_status = exec("/app/src/docker_runner.sh #{cid} #{max_seconds}")
    assert_success(output, exit_status)
    return [output, exit_status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def exec(command)
    output, exit_status = shell.exec(command)
    assert_success(output, exit_status)
    return [output, exit_status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_success(output, exit_status)
    fail "exited(#{exit_status}):#{output}:" unless exit_status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def disk; nearest_ancestors(:disk); end

  def shell; nearest_ancestors(:shell); end

  def success; 0; end

end
