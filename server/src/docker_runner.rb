require_relative './nearest_ancestors'

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

  def create_container(image_name, kata_id, avatar_name)
    # This creates the container but docker_runner.sh removes it.
    # Mounts new_avatar's volume in /sandbox
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      '--user=root',
      "--volume=#{volume_name(kata_id, avatar_name)}:/sandbox"
    ].join(space = ' ')
    output, _ = assert_exec("docker run #{args} #{image_name} sh")
    cid = output.strip
    # Change ownership of /sandbox
    assert_exec("docker exec #{cid} sh -c 'chown #{user}:#{group} #{sandbox}'")
    cid
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleted_files(cid, filenames)
    # filenames have been deleted in the browser
    # so delete them from the container.
    filenames.each do |filename|
      assert_exec("docker exec #{cid} sh -c 'rm #{sandbox}/#{filename}'")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def changed_files(cid, files)
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
    # docker_runner.sh does a [docker rm CID] in a child process
    # (for the max_seconds timeout).
    # This has a race-condition and can issue a diagnostic to stderr,
    #   Error response from daemon: No such exec instance
    #          'cfc1ce94ec97f86ad0a73c6f.....' found in daemon
    # Tests show the container _is_ removed.
    # I pipe stderr to /dev/null so the diagnostic does not appear in test output.
    exec("/app/src/docker_runner.sh #{cid} #{max_seconds} 2> /dev/null")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  private

  def image_names
    output, _ = assert_exec('docker images')
    # REPOSITORY                               TAG    IMAGE ID     CREATED     SIZE
    # cyberdojofoundation/ruby_test_unit       latest fd0b425fb21d 7 weeks ago 126 MB
    # cyberdojofoundation/java_cucumber_spring latest 7f59c6590213 7 weeks ago 885.7 MB
    output[1..-1].split("\n").collect { |line| line.split[0] }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_exec(command)
    output, status = exec(command)
    fail "exited(#{status}):#{output}:" unless status == success
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
  def success; 0; end
  def sandbox; '/sandbox'; end
  def user; 'nobody'; end
  def group; 'nogroup'; end

end
