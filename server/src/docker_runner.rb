
require_relative './nearest_ancestors'

class DockerRunner

  def initialize(parent)
    @parent = parent
  end

  attr_reader :parent

  def pulled?(image_name)
    [ '', image_names.include?(image_name) ]
  end

  def pull(image_name)
    exec("docker pull #{image_name}")
  end

  def start(kata_id, avatar_name)
    volume_name = "cyber_dojo_#{kata_id}_#{avatar_name}"
    exec("docker volume create --name #{volume_name}")
  end

  def create_container(image_name, kata_id, avatar_name)
    # This creates the container but docker_runner.sh removes it.
    volume_name = "cyber_dojo_#{kata_id}_#{avatar_name}"
    # Assume volume exists from previous /start
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      '--user=root',
      "--volume=#{volume_name}:/sandbox"
    ].join(space = ' ')
    output, _ = assert_exec("docker run #{args} #{image_name} sh")
    cid = output.strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleted_files(cid, filenames)
    filenames.each do |filename|
      assert_exec("docker exec #{cid} sh -c 'rm /sandbox/#{filename}'")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def changed_files(cid, files)
    # copy changed files into sandbox
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        pathed_filename = tmp_dir + '/' + filename
        disk.write(pathed_filename, content)
        assert_exec("chmod +x #{pathed_filename}") if pathed_filename.end_with?('.sh')
      end
      assert_exec("docker cp #{tmp_dir}/. #{cid}:/sandbox")
    end
    # ensure nobody:nogroup owns changed files
    # Ubuntu and Alpine images both have nobody and nogroup
    assert_exec("docker exec #{cid} sh -c 'chown -R nobody:nogroup /sandbox'")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def setup_home(cid, image_name)
    # The existing C#-NUnit image picks up HOME from the _current_ user.
    # The nobody user quite probably does not have a home dir.
    # I usermod to solve this. The C#-NUnit docker image is built
    # from an Ubuntu base which has usermod.
    if image_name == 'cyberdojofoundation/csharp_nunit'
      assert_exec("docker exec #{cid} sh -c 'usermod --home /sandbox nobody 2> /dev/null'")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(cid, max_seconds)
    # docker_runner.sh does a [docker rm CID] in a child process
    # (for the max_seconds timeout).
    # This has a race-condition and can issue a diagnostic to stderr, eg
    #   Error response from daemon: No such exec instance
    #          'cfc1ce94ec97f86ad0a73c6f.....' found in daemon
    # Tests show the container _is_ removed.
    # The race makes it awkard for tests to remove the volume.
    # (see the external_teardown in server/test/src/docker_runner_helpers.rb)
    # I pipe stderr to /dev/null so the diagnostic does not appear in test output.
    exec("/app/src/docker_runner.sh #{cid} #{max_seconds} 2> /dev/null")
  end

  private

  def image_names
    output, _ = assert_exec('docker images')
    output.split("\n").collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_exec(command)
    output, status = exec(command)
    fail "exited(#{status}):#{output}:" unless status == success
    [output, status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def exec(command)
    shell.exec(command)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestAncestors
  def disk;  nearest_ancestors(:disk);  end
  def shell; nearest_ancestors(:shell); end

  def success; 0; end

end
