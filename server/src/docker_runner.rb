require_relative './nearest_ancestors'
require 'timeout'

class DockerRunner

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def pulled?(image_name)
    ['', image_names.include?(image_name)]
  end

  def pull(image_name)
    exec("docker pull #{image_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def hello(kata_id, avatar_name)
    _, status = exec("docker volume create --name #{volume_name(kata_id, avatar_name)}")
    ['', status]
  end

  def goodbye(kata_id, avatar_name)
    _, status = exec("docker volume rm #{volume_name(kata_id, avatar_name)}")
    ['', status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # TODO: put run() here

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def create_container(image_name, kata_id, avatar_name)
    # This creates the container but docker_runner.sh removes it.
    # Mounts new_avatar's volume in /sandbox
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
    # Change ownership of /sandbox
    assert_exec("docker exec #{cid} sh -c 'chown #{user}:#{group} #{sandbox}'")
    cid
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, filenames)
    # filenames have been deleted in the browser
    # so delete them from the container.
    filenames.each do |filename|
      assert_exec("docker exec #{cid} sh -c 'rm #{sandbox}/#{filename}'")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def change_files(cid, files)
    # files have been created or changed in the browser
    # so create or change them in the container.
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
        assert_exec("chmod +x #{host_filename}") if filename.end_with?('.sh')
      end
      # The dot in this command is very important.
      # See https://docs.docker.com/engine/reference/commandline/cp/
      assert_exec("docker cp #{tmp_dir}/. #{cid}:#{sandbox}")
    end
    # ensure nobody:nogroup owns changed files.
    # Ubuntu and Alpine images both have nobody and nogroup
    files.keys.each do |filename|
      assert_exec("docker exec #{cid} sh -c 'chown #{user}:#{group} #{sandbox}/#{filename}'")
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
    # So this is not assert_exec(...)
    exec("docker exec #{cid} sh -c 'usermod --home #{sandbox} #{user} 2> /dev/null'")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(cid, max_seconds)
    cmd = [
      'docker exec',
      "--user=nobody",
      "--interactive",
      cid,
      'sh -c',
      "./cyber-dojo.sh 2>&1"
    ].join(space = ' ')

    # http://stackoverflow.com/questions/8292031/ruby-timeouts-and-system-commands
    rout, wout = IO.pipe
    rerr, werr = IO.pipe

    pid = Process.spawn(cmd, pgroup:true, out:wout, err:werr)
    begin
      Timeout::timeout(max_seconds) do
        Process.waitpid(pid)
        wout.close
        werr.close
        stdout = rout.readlines.join
        _stderr = rerr.readlines.join
        #puts "run():Process.spawn(#{cmd})-stdout:#{stdout}:"
        return [stdout, success]
      end
    rescue Timeout::Error
      Process.kill(-9, pid)
      Process.detach(pid)
      return ['', timed_out_and_killed]
    ensure
      wout.close unless wout.closed?
      werr.close unless werr.closed?
      rout.close
      rerr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # TODO: shell.exec()->exec
  # TODO: error handling
  def remove_container(cid)
    # ask the docker daemon to remove the container
    shell.exec("docker rm -f #{cid}")
    # wait max 2 secs till it's gone
    200.times do
      # do the sleep first to keep test coverage at 100%
      sleep(1.0 / 100.0)
      break if container_dead?(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sandbox; '/sandbox'; end
  def success; 0; end
  def timed_out_and_killed; (timed_out = 128) + (killed = 9); end

  private # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

  def image_names
    output, _ = assert_exec('docker images')
    # REPOSITORY                               TAG    IMAGE ID     CREATED     SIZE
    # cyberdojofoundation/ruby_test_unit       latest fd0b425fb21d 7 weeks ago 126 MB
    # cyberdojofoundation/java_cucumber_spring latest 7f59c6590213 7 weeks ago 885.7 MB
    output[1..-1].split("\n").collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?(cid)
    # See https://gist.github.com/ekristen/11254304
    cmd = "docker inspect --format='{{ .State.Running }}' #{cid} 2> /dev/null"
    _, status = exec(cmd)
    dead = status == 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_exec(cmd)
    output, status = exec(cmd)
    fail "exited(#{status}):#{output}:" unless status == success
    #puts "assert_exec(#{cmd})-status:#{status}:"
    #puts "assert_exec(#{cmd})-output:#{output}:"
    [output, status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_name(kata_id, avatar_name)
    "cyber_dojo_#{kata_id}_#{avatar_name}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestAncestors
  def disk;  nearest_ancestors(:disk);  end
  def shell; nearest_ancestors(:shell); end
  def exec(command); shell.exec(command); end

  def user; 'nobody'; end
  def group; 'nogroup'; end

end
