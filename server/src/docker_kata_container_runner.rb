require_relative 'all_avatars_names'
require_relative 'nearest_ancestors'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require 'timeout'

# new_kata()  creates a docker-volume inside
#             a container with a cmd of sleep 1d
# run()       docker exec's directly into the container
#             and does not then remove the container.

class DockerRunner

  def initialize(parent)
    @parent = parent
    @logging = true
  end

  attr_reader :parent

  def logging_off; @logging = false; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def pull(image_name)
    assert_exec("docker pull #{image_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(_image_name, kata_id)
    assert_valid_id(kata_id)

    name = container_name(kata_id)
    cmd = "docker ps --quiet --all --filter name=#{name}"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def new_kata(image_name, kata_id)
    refute_kata_exists(kata_id)

    name = container_name(kata_id)
    args = [
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      '--detach',
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      '--user=root',
      "--volume #{sandboxes_root}",
      "--name=#{name}"
    ].join(space)
    cmd = "docker run #{args} #{image_name} sh -c 'sleep 1d'"
    assert_exec(cmd)
  end

  def old_kata(image_name, kata_id)
    assert_kata_exists(kata_id)

    name = container_name(kata_id)
    cmd = "docker rm --force --volumes #{name}"
    assert_exec(cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(_image_name, kata_id, avatar_name)
    assert_kata_exists(kata_id)
    assert_valid_name(avatar_name)

    name = container_name(kata_id)
    sandbox = sandbox_path(avatar_name)
    cmd = "docker exec #{name} sh -c '[ -d #{sandbox} ]'"
    _,_,status = exec(cmd, logging = false)
    status == success
  end

  def new_avatar(_image_name, kata_id, avatar_name, starting_files)
    assert_kata_exists(kata_id)
    refute_avatar_exists(kata_id, avatar_name)

    name = container_name(kata_id)
    sandbox = sandbox_path(avatar_name)
    mkdir = "mkdir #{sandbox}"
    assert_docker_exec(name, mkdir)
    uid = user_id(avatar_name)
    chown = "chown #{uid}:#{group} #{sandbox}"
    assert_docker_exec(name, chown)
    write_files(kata_id, avatar_name, starting_files)
  end

  def old_avatar(_image_name, kata_id, avatar_name)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)

    name = container_name(kata_id)
    sandbox = sandbox_path(avatar_name)
    rm = "rm -rf #{sandbox}"
    assert_docker_exec(name, rm)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(_image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)

    delete_files(kata_id, avatar_name, deleted_filenames)
    write_files(kata_id, avatar_name, changed_files)
    stdout,stderr,status = run_cyber_dojo_sh(kata_id, avatar_name, max_seconds)
    stdout = truncated(cleaned(stdout))
    stderr = truncated(cleaned(stderr))
    { stdout:stdout, stderr:stderr, status:status }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # properties
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user_id(avatar_name)
    assert_valid_name(avatar_name)
    40000 + all_avatars_names.index(avatar_name)
  end

  def group
    'nogroup'
  end

  def sandbox_path(avatar_name)
    assert_valid_name(avatar_name)
    "#{sandboxes_root}/#{avatar_name}"
  end

  private # ==========================================================

  include StringCleaner
  include StringTruncater

  def delete_files(kata_id, avatar_name, filenames)
    cid = container_name(kata_id)
    sandbox = sandbox_path(avatar_name)
    filenames.each do |filename|
      rm = "rm #{sandbox}/#{filename}"
      assert_docker_exec(cid, rm)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def write_files(kata_id, avatar_name, files)
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
        if filename.end_with?('.sh')
          assert_exec("chmod +x #{host_filename}")
        end
      end
      uid = user_id(avatar_name)
      cid = container_name(kata_id)
      sandbox = sandbox_path(avatar_name)
      cmd = [
        'tar',                # Tar Pipe
          "--owner=#{uid}",   # force ownership
          "--group=#{group}", # force group
          '-cf',              # create a new archive
          '-',                # write archive to stdout
          '-C',               # change to...
          "#{tmp_dir}",       # ...this dir
          '.',                # ...and archive it
          '| docker exec',    # pipe stdout to docker
            "-i #{cid}",      # container
            'tar',            #
            '-xf',            # extract archive
            '-',              # read archive from stdin
            '-C',             # change to...
            sandbox           # ...this dir and extract
      ].join(space)
      assert_exec(cmd)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(kata_id, avatar_name, max_seconds)
    # I thought doing [chmod 755] in new_avatar() would
    # be "sticky" and remain 755 but it appears not...
    cid = container_name(kata_id)
    uid = user_id(avatar_name)
    sandbox = sandbox_path(avatar_name)

    cmd = [
      "export CYBER_DOJO_KATA_ID=#{kata_id}",
      "export CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "cd #{sandbox}",
      'chmod 755 .',
      './cyber-dojo.sh'
    ].join('&&')

    exec = [
      'docker exec',
      "--user=#{uid}",
      '--interactive',
      cid,
      "sh -c '#{cmd}'"
    ].join(space)

    r_stdout, w_stdout = IO.pipe
    r_stderr, w_stderr = IO.pipe
    pid = Process.spawn(exec, pgroup:true, out:w_stdout, err:w_stderr)
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
      ['', '', 'timed_out']
    ensure
      w_stdout.close unless w_stdout.closed?
      w_stderr.close unless w_stderr.closed?
      r_stdout.close
      r_stderr.close
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def refute_kata_exists(kata_id)
    assert_valid_id(kata_id)
    if kata_exists?(nil, kata_id)
      fail_kata_id('exists')
    end
  end

  def assert_kata_exists(kata_id)
    assert_valid_id(kata_id)
    unless kata_exists?(nil, kata_id)
      fail_kata_id('!exists')
    end
  end

  def assert_valid_id(kata_id)
    unless valid_id?(kata_id)
      fail_kata_id('invalid')
    end
  end

  def valid_id?(kata_id)
    kata_id.class.name == 'String' &&
      kata_id.length == 10 &&
        kata_id.chars.all? { |char| hex?(char) }
  end

  def hex?(char)
    '0123456789ABCDEF'.include?(char)
  end

  def fail_kata_id(message)
    fail argument("kata_id:#{message}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def refute_avatar_exists(kata_id, avatar_name)
    assert_valid_name(avatar_name)
    if avatar_exists?(nil, kata_id, avatar_name)
      fail_avatar_name('exists')
    end
  end

  def assert_avatar_exists(kata_id, avatar_name)
    assert_valid_name(avatar_name)
    unless avatar_exists?(nil, kata_id, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def assert_valid_name(avatar_name)
    unless valid_avatar?(avatar_name)
      fail_avatar_name('invalid')
    end
  end

  include AllAvatarsNames
  def valid_avatar?(avatar_name)
    all_avatars_names.include?(avatar_name)
  end

  def fail_avatar_name(message)
    fail argument("avatar_name:#{message}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  def assert_exec(cmd)
    stdout,stderr,status = exec(cmd)
    unless status == success
      fail StandardError.new(cmd)
    end
    [stdout,stderr]
  end

  def exec(cmd, logging = @logging)
    shell.exec(cmd, logging)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_names
    cmd = 'docker images --format "{{.Repository}}"'
    stdout,_ = assert_exec(cmd)
    names = stdout.split("\n")
    names.uniq - ['<none']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_name(kata_id)
    [ 'cyber', 'dojo', kata_id ].join('_')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def argument(message)
    ArgumentError.new(message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sandboxes_root; '/sandboxes'; end
  def success; shell.success; end
  def space; ' '; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestAncestors
  def shell; nearest_ancestors(:shell); end
  def  disk; nearest_ancestors(:disk ); end

end

=begin
def create_user_cmd(avatar_name)
    if alpine?
      return [
        'adduser',
        '-D',                          # passwordless access
        "-h #{sandbox(avatar_name)}",  # home dir
        avatar_name
      ].join(space = ' ')
    end
    if ubuntu?
      return [
        'adduser',
        "--home #{sandbox(avatar_name)}",   # home dir
        '--disabled-password',              # passwordless access
        "--gecos \"\" #{avatar_name}"       # don't ask for details
      ].join(space =' ')
    end
    # nil
  end

  def alpine?; etc_issue.include?('Alpine'); end
  def ubuntu?; etc_issue.include?('Ubuntu'); end
  def etc_issue; assert_docker_exec(cid, 'cat /etc/issue')[0]; end
=end
