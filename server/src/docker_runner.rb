require_relative './nearest_external'
require 'timeout'

class DockerRunner

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def pulled_image?(image_name)
    ['', image_names.include?(image_name)]
  end

  def pull_image(image_name)
    exec("docker pull #{image_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(kata_id, avatar_name)
    assert_exec("docker volume create --name #{volume_name(kata_id, avatar_name)}")
  end

  def old_avatar(kata_id, avatar_name)
    assert_exec("docker volume rm #{volume_name(kata_id, avatar_name)}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    cid = create_container(image_name, kata_id, avatar_name)
    begin
      delete_files(cid, deleted_filenames)
      change_files(cid, changed_files)
      setup_home(cid)
      run_cyber_dojo_sh(cid, max_seconds)
    ensure
      remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def create_container(image_name, kata_id, avatar_name)
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      "--workdir=#{sandbox}",
      '--user=root',
      "--volume=#{volume_name(kata_id, avatar_name)}:#{sandbox}"
    ].join(space = ' ')
    output, _ = assert_exec("docker run #{args} #{image_name} sh")
    cid = output.strip
    assert_docker_exec(cid, "chown #{user}:#{group} #{sandbox}")
    cid
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
      assert_docker_exec(cid, "chown #{user}:#{group} #{sandbox}/#{filename}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def setup_home(cid)
    # Some languages need the current user to have a home.
    # They are all Ubuntu image based, eg C#-NUnit, F#-NUnit.
    # The nobody user does not have a home dir in Ubuntu.
    # usermod solves this. Rather than switch on the image_name
    # or probe to determine if the image is Ubuntu based, I always
    # run usermod and it does nothing on Alpine based images
    # which do not have usermod (its in the shadow package).
    # So this is not assert_exec(...) and logging is off
    usermod = "usermod --home #{sandbox} #{user} 2> /dev/null"
    exec("docker exec #{cid} sh -c '#{usermod}'", logging = false)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, max_seconds)
    cmd = "docker exec --user=#{user} --interactive #{cid} sh -c './cyber-dojo.sh'"
    read_out, write_out = IO.pipe
    read_err, write_err = IO.pipe
    pid = Process.spawn(cmd, pgroup:true, out:write_out, err:write_err)
    begin
      Timeout::timeout(max_seconds) do
        Process.waitpid(pid)
        write_out.close
        write_err.close
        [completed, read_out.readlines.join, read_err.readlines.join]
      end
    rescue Timeout::Error
      Process.kill(-9, pid)
      Process.detach(pid)
      [timed_out, '', '']
    ensure
      write_out.close unless write_out.closed?
      write_err.close unless write_err.closed?
      read_out.close
      read_err.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    200.times do
      sleep(1.0 / 100.0)
      break if container_dead?(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user; 'nobody'; end
  def group; 'nogroup'; end
  def sandbox; '/sandbox'; end

  def completed;   0; end
  def timed_out; 128; end

  private

  def image_names
    output, _ = assert_exec('docker images')
    output[1..-1].split("\n").collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?(cid)
    cmd = "docker inspect --format='{{ .State.Running }}' #{cid} 2> /dev/null"
    _, status = exec(cmd, logging = false)
    dead = status == 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  def assert_exec(cmd)
    output, status = exec(cmd)
    fail "exited(#{status}):#{output}:" unless status == 0
    [output, status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_name(kata_id, avatar_name)
    "cyber_dojo_#{kata_id}_#{avatar_name}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestExternal
  def disk;  nearest_external(:disk);  end
  def shell; nearest_external(:shell); end
  def exec(cmd, logging = true); shell.exec(cmd, logging); end

end
