require_relative 'all_avatars_names'
require_relative 'nearest_ancestors'
require_relative 'string_cleaner'
require_relative 'string_truncater'
require 'timeout'

# new_kata()  creates a docker-volume inside
#             a data-only container
# run()       remounts the data-only-container into a new
#             container then removes the run-container

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
    name = sandboxes_data_only_container_name(kata_id)
    cmd = "docker ps --quiet --all --filter name=#{name}"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def new_kata(image_name, kata_id)
    refute_kata_exists(image_name, kata_id)
    name = sandboxes_data_only_container_name(kata_id)
    cmd = [
      'docker run',
        "--volume #{sandboxes_root}",
        "--name=#{name}",
        image_name,
        '/bin/true'
    ].join(space)
    assert_exec(cmd)
  end

  def old_kata(image_name, kata_id)
    assert_kata_exists(image_name, kata_id)
    name = sandboxes_data_only_container_name(kata_id)
    cmd = "docker rm --volumes #{name}"
    assert_exec(cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(image_name, kata_id, avatar_name)
    cid = create_container(image_name, kata_id, avatar_name)
    begin
      avatar_exists_cid?(cid, avatar_name)
    ensure
      remove_container(cid)
    end
  end

  def new_avatar(image_name, kata_id, avatar_name, starting_files)
    cid = create_container(image_name, kata_id, avatar_name)
    begin
      refute_avatar_exists(cid, avatar_name)
      sandbox = sandbox_path(avatar_name)
      mkdir = "mkdir #{sandbox}"
      assert_docker_exec(cid, mkdir)
      uid = user_id(avatar_name)
      chown = "chown #{uid}:#{group} #{sandbox}"
      assert_docker_exec(cid, chown)
      write_files(cid, avatar_name, starting_files)
    ensure
      remove_container(cid)
    end
  end

  def old_avatar(image_name, kata_id, avatar_name)
    cid = create_container(image_name, kata_id, avatar_name)
    begin
      assert_avatar_exists(cid, avatar_name)
      sandbox = sandbox_path(avatar_name)
      rm = "rm -rf #{sandbox}"
      assert_docker_exec(cid, rm)
    ensure
      remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    cid = create_container(image_name, kata_id, avatar_name)
    begin
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      stdout = truncated(cleaned(stdout))
      stderr = truncated(cleaned(stderr))
      { stdout:stdout, stderr:stderr, status:status }
    ensure
      remove_container(cid)
    end
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

  def create_container(image_name, kata_id, avatar_name)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts the kata's volume
    #     [docker run ... --volume=V:/sandboxes:rw  ...]
    # Volume V must exist via an earlier new_kata() call
    # because if volume V does _not_ exist the [docker run]
    # would nevertheless succeed, create the container,
    # and create a (temporary) /sandboxes/ folder in it!
    # See https://github.com/docker/docker/issues/13121
    assert_valid_id(kata_id)
    assert_kata_exists(image_name, kata_id)
    assert_valid_name(avatar_name)
    sandbox = sandbox_path(avatar_name)
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{sandbox}",
      '--user=root',
      "--volumes-from=#{sandboxes_data_only_container_name(kata_id)}:rw"
    ].join(space)
    stdout,_,_ = assert_exec("docker run #{args} #{image_name} sh")
    cid = stdout.strip
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, avatar_name, filenames)
    sandbox = sandbox_path(avatar_name)
    filenames.each do |filename|
      rm = "rm #{sandbox}/#{filename}"
      assert_docker_exec(cid, rm)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def write_files(cid, avatar_name, files)
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
        if filename.end_with?('.sh')
          assert_exec("chmod +x #{host_filename}")
        end
      end
      uid = user_id(avatar_name)
      sandbox = sandbox_path(avatar_name)
      cmd = [
          'tar',              # Tar Pipe
          "--owner=#{uid}",   # force ownership
          "--group=#{group}", # force group
          '-cf',              # create a new archive
          '-',                # write archive to stdout
          '-C',               # change to...
          "#{tmp_dir}",       # ...this dir
          '.',                # ...and archive it
          '|',                # pipe stdout to...
          'docker exec',      # docker
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

  def run_cyber_dojo_sh(cid, avatar_name, max_seconds)
    # I thought doing [chmod 755] in new_avatar() would
    # be "sticky" and remain 755 but it appears not...
    uid = user_id(avatar_name)
    sandbox = sandbox_path(avatar_name)
    cmd = [
      'docker exec',
      "--user=#{uid}",
      '--interactive',
      cid,
      "sh -c 'cd #{sandbox} && chmod 755 . && ./cyber-dojo.sh'"
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
      ['', '', 'timed_out']
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

  def container_dead?(cid)
    cmd = "docker inspect --format='{{ .State.Running }}' #{cid}"
    _,stderr,status = exec(cmd, logging = false)
    expected_stderr = "Error: No such image, container or task: #{cid}"
    (status == 1) && (stderr.strip == expected_stderr)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

  def refute_kata_exists(image_name, kata_id)
    if kata_exists?(image_name, kata_id)
      fail_kata_id('exists')
    end
  end

  def assert_kata_exists(image_name, kata_id)
    unless kata_exists?(image_name, kata_id)
      fail_kata_id('!exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_valid_name(avatar_name)
    unless valid_avatar?(avatar_name)
      fail_avatar_name('invalid')
    end
  end

  include AllAvatarsNames
  def valid_avatar?(avatar_name)
    all_avatars_names.include?(avatar_name)
  end

  def refute_avatar_exists(cid, avatar_name)
    if avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('exists')
    end
  end

  def assert_avatar_exists(cid, avatar_name)
    unless avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def avatar_exists_cid?(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    cmd = "docker exec #{cid} sh -c '[ -d #{sandbox} ]'"
    _,_,status = exec(cmd, logging = false)
    status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def fail_kata_id(message)
    fail argument("kata_id:#{message}")
  end

  def fail_avatar_name(message)
    fail argument("avatar_name:#{message}")
  end

  def argument(message)
    ArgumentError.new(message)
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

  def sandboxes_data_only_container_name(kata_id)
    [ 'cyber', 'dojo', kata_id ].join('_')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sandboxes_root; '/sandboxes'; end
  def success; shell.success; end
  def space; ' '; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestAncestors
  def shell; nearest_ancestors(:shell); end
  def  disk; nearest_ancestors(:disk ); end
  def   log; nearest_ancestors(:log  ); end

end
