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
    assert_exec("docker volume create --name #{volume_name(kata_id, avatar_name)}")
  end

  def goodbye(kata_id, avatar_name)
    assert_exec("docker volume rm #{volume_name(kata_id, avatar_name)}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
    cid = create_container(image_name, kata_id, avatar_name)
    delete_files(cid, deleted_filenames)
    change_files(cid, changed_files)
    setup_home(cid)
    status, stdout, stderr = run_cyber_dojo_sh(cid, max_seconds)
    remove_container(cid)
    [status, stdout, stderr]
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
    chown = "chown #{user}:#{group} #{sandbox}"
    assert_docker_exec(cid, chown)
    cid
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, filenames)
    filenames.each do |filename|
      rm = "rm #{sandbox}/#{filename}"
      assert_docker_exec(cid, rm)
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
      # The dot in this command is very important.
      # See https://docs.docker.com/engine/reference/commandline/cp/
      assert_exec("docker cp #{tmp_dir}/. #{cid}:#{sandbox}")
    end
    files.keys.each do |filename|
      chown = "chown #{user}:#{group} #{sandbox}/#{filename}"
      assert_docker_exec(cid, chown)
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
    cmd = [
      'docker exec',
      "--user=#{user}",
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
        stderr = rerr.readlines.join
        #puts "run_cyber_dojo_sh():Process.spawn(#{cmd})-stdout:#{stdout}:"
        #puts "run_cyber_dojo_sh():Process.spawn(#{cmd})-stdout:#{stderr}:"
        [completed, stdout, stderr]
      end
    rescue Timeout::Error
      # don't attempt to retrieve stdout,stderr. It blocks
      Process.kill(-9, pid)
      Process.detach(pid)
      [timed_out, '', '']
    ensure
      wout.close unless wout.closed?
      werr.close unless werr.closed?
      rout.close
      rerr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    200.times do # try max 2 secs
      sleep(1.0 / 100.0) # sleep then break to keep coverage at 100%
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
    # REPOSITORY                               TAG    IMAGE ID     CREATED     SIZE
    # cyberdojofoundation/ruby_test_unit       latest fd0b425fb21d 7 weeks ago 126 MB
    # cyberdojofoundation/java_cucumber_spring latest 7f59c6590213 7 weeks ago 885.7 MB
    output[1..-1].split("\n").collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?(cid)
    # See https://gist.github.com/ekristen/11254304
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
  def exec(cmd, logging = true); shell.exec(cmd, logging); end

end
