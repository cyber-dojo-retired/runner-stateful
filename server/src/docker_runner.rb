require_relative 'all_avatars_names'
require_relative 'nearest_external'
require_relative 'string_cleaner'
require_relative 'string_truncater'

require 'timeout'

class DockerRunner

  def initialize(parent)
    @parent = parent
    @logging = true
  end

  attr_reader :parent

  def logging_off; @logging = false; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def pulled(image_name); pulled?(image_name); end

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def pull(image_name)
    assert_exec("docker pull #{image_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_kata(image_name, kata_id)
    pull(image_name) unless pulled?(image_name)
    @kata_id = kata_id
    assert_exec("docker volume create --name #{volume_name}")
  end

  def old_kata(kata_id)
    @kata_id = kata_id
    assert_exec("docker volume rm #{volume_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(image_name, kata_id, avatar_name, starting_files)
    @image_name = image_name
    @kata_id = kata_id
    @avatar_name = avatar_name
    cid = create_container
    begin
      cmd = "mkdir #{sandbox}"
      assert_docker_exec(cid, cmd)
      cmd = "chown #{user}:#{group} #{sandbox}"
      assert_docker_exec(cid, cmd)
      change_files(cid, starting_files)
    ensure
      remove_container(cid)
    end
  end

  def old_avatar(_kata_id, _avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    @image_name = image_name
    @kata_id = kata_id
    @avatar_name = avatar_name
    cmd = "docker volume ls --quiet --filter 'name=#{volume_name}'"
    stdout,stderr = assert_exec(cmd)
    fail ArgumentError.new('no_kata') unless stdout.strip == volume_name
    cid = create_container
    begin
      delete_files(cid, deleted_filenames)
      change_files(cid, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, max_seconds)
      stdout = truncated(cleaned(stdout))
      stderr = truncated(cleaned(stderr))
      { stdout:stdout, stderr:stderr, status:status }
    ensure
      remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user; 40000 + all_avatars_names.index(@avatar_name); end
  def group; 'nogroup'; end
  def sandbox; "#{sandboxes_root}/#{@avatar_name}"; end

  def success; shell.success; end
  def timed_out; 'timed_out'; end

  private

  include AllAvatarsNames
  include StringCleaner
  include StringTruncater

  def create_container
    # Volume mounts the avatar's volume
    #     [docker run ... --volume=V:/sandboxes:rw  ...]
    # Volume V is assumed to exist via an earlier new_kata() call.
    # If volume V does _not_ exist the [docker run] will nevertheless
    # succeed, create the container, and create a /sandboxes/ folder in it!
    # https://github.com/docker/docker/issues/13121
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      "--env CYBER_DOJO_KATA_ID=#{@kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{@avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{sandbox}",
      '--user=root',
      "--volume=#{volume_name}:/#{sandboxes_root}:rw"
    ].join(space)
    cid = assert_exec("docker run #{args} #{@image_name} sh")[0].strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, filenames)
    filenames.each do |filename|
      assert_docker_exec(cid, "rm #{sandbox}/#{filename}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def change_files(cid, files)
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
        assert_exec("chmod +x #{host_filename}") if filename.end_with?('.sh')
      end
      assert_exec("docker cp #{tmp_dir}/. #{cid}:#{sandbox}")
    end
    files.keys.each do |filename|
      cmd = "chown #{user}:#{group} #{sandbox}/#{filename}"
      assert_docker_exec(cid, cmd)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, max_seconds)
    cmd = [
      'docker exec',
      "--user=#{user}",
      '--interactive',
      cid,
      "sh -c 'cd #{sandbox} && ./cyber-dojo.sh'"
    ].join(space)
    r_stdout, w_stdout = IO.pipe
    r_stderr, w_stderr = IO.pipe
    pid = Process.spawn(cmd, pgroup:true, out:w_stdout, err:w_stderr)
    begin
      Timeout::timeout(max_seconds) do
        Process.waitpid(pid)
        status = $?.exitstatus
        w_stdout.close
        w_stderr.close
        [r_stdout.read, r_stderr.read, status]
      end
    rescue Timeout::Error
      Process.kill(-9, pid)
      Process.detach(pid)
      ['', '', timed_out]
    ensure
      w_stdout.close unless w_stdout.closed?
      w_stderr.close unless w_stderr.closed?
      r_stdout.close
      r_stderr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    # The docker daemon responds to [docker rm] asynchronously...
    # An 'immediately' following old_avatar()'s [docker volume rm]
    # might fail since the container is not quite dead yet.
    # This is unlikely to happen in real use but quite likely in tests.
    # I considered making old_avatar() check the container was dead.
    #   pro) remove_container will never do a sleep (delaying a run)
    #   con) would mean storing the cid in the volume somewhere
    # For now I'm waiting max 2 seconds for the container to die.
    # Note: no delay if container_dead? is true 1st time.
    # Note: 0.04s delay if the container_dead? is true 2nd time.
    removed = false
    tries = 0
    while !removed && tries < 50
      removed = container_dead?(cid)
      sleep(1.0 / 25.0) unless removed
      tries += 1
    end
    log << "Failed:remove_container(#{cid})" unless removed
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_names
    lines = assert_exec('docker images')[0].split("\n")
    lines.shift # REPOSITORY TAG IMAGE ID CREATED SIZE
    lines.collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_name
    "cyber_dojo_#{@kata_id}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?(cid)
    cmd = "docker inspect --format='{{ .State.Running }}' #{cid}"
    _,stderr,status = exec(cmd, logging = false)
    expected_stderr = "Error: No such image, container or task: #{cid}"
    (status == 1) && (stderr.strip == expected_stderr)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  def assert_exec(cmd)
    stdout,stderr,status = exec(cmd)
    fail StandardError.new(cmd) unless status == success
    [stdout,stderr]
  end

  def exec(cmd, logging = @logging)
    shell.exec(cmd, logging)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def space; ' '; end
  def sandboxes_root; '/sandboxes'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestExternal
  def shell; nearest_external(:shell); end
  def  disk; nearest_external(:disk);  end
  def   log; nearest_external(:log);   end

end
