require_relative 'docker_runner'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new docker container per run().
# Uses a docker volume per kata.
#
# Positives:
#   o) the cyber-dojo.sh process is running as pid-1
#      which is a robust way of ensuring the entire
#      process tree is killed.
#
# Negatives:
#   o) increased run() time (compared to one container per kata)
#   o) no possibility of avatars having shared state.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerKataVolumeRunner

  def initialize(parent)
    @parent = parent
    @logging = true
  end

  include DockerRunner

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
      mkdir = "mkdir -m 755 #{sandbox}"
      assert_docker_exec(cid, mkdir)
      uid = user_id(avatar_name)
      chown = "chown #{uid}:#{gid} #{sandbox}"
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
  # Copes with infinite loops (eg) in the avatar's code/tests by
  # removing the container - which obviously kills all processes
  # running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    cid = create_container(image_name, kata_id, avatar_name)
    begin
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      { stdout:stdout, stderr:stderr, status:status }
    ensure
      remove_container(cid)
    end
  end

  private # ==========================================================

  def create_container(image_name, kata_id, avatar_name)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts the kata's volume
    #     [docker run ... --volume=V:/sandboxes:rw  ...]
    # Volume V must exist via an earlier new_kata() call.
    # If volume V does _not_ exist the [docker run]
    # will nevertheless succeed, create the container,
    # and create a (temporary) /sandboxes/ folder in it!
    # See https://github.com/docker/docker/issues/13121
    assert_valid_id(kata_id)
    assert_kata_exists(image_name, kata_id)
    assert_valid_name(avatar_name)
    sandbox = sandbox_path(avatar_name)
    home = home_path(avatar_name)
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{sandbox}",
      "--env HOME=#{home}",
      '--user=root',
      "--volumes-from=#{sandboxes_data_only_container_name(kata_id)}:rw"
    ].join(space)
    stdout,_,_ = assert_exec("docker run #{args} #{image_name} sh")
    cid = stdout.strip

    cmd = [
      add_group_cmd(cid),
      add_user_cmd(cid, avatar_name)
    ].join('&&')
    assert_docker_exec(cid, cmd)

    cid
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def add_group_cmd(cid)
    if alpine? cid
      return alpine_add_group_cmd
    end
    if ubuntu? cid
      return ubuntu_add_group_cmd
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def add_user_cmd(cid, avatar_name)
    if alpine? cid
      return alpine_add_user_cmd(avatar_name)
    end
    if ubuntu? cid
      return ubuntu_add_user_cmd(avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def alpine?(cid)
    etc_issue(cid).include?('Alpine')
  end

  def ubuntu?(cid)
    etc_issue(cid).include?('Ubuntu')
  end

  def etc_issue(cid)
    stdout,_ = assert_docker_exec(cid, 'cat /etc/issue')
    stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, avatar_name, filenames)
    return if filenames == []
    sandbox = sandbox_path(avatar_name)
    all = filenames.map { |filename| "#{sandbox}/#{filename}" }
    rm = 'rm ' + all.join(space)
    assert_docker_exec(cid, rm)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def write_files(cid, avatar_name, files)
    return if files == {}
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
      end
      uid = user_id(avatar_name)
      sandbox = sandbox_path(avatar_name)
      docker_cp = "docker cp #{tmp_dir}/. #{cid}:#{sandbox}"
      assert_exec(docker_cp)
      all = files.keys.map { |filename| "#{sandbox}/#{filename}" }
      chown = "chown #{uid}:#{gid} " + all.join(space)
      assert_docker_exec(cid, chown)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, avatar_name, max_seconds)
    # I thought doing [chmod 755] in new_avatar() would
    # be "sticky" and remain 755 but it appears not...
    uid = user_id(avatar_name)
    sandbox = sandbox_path(avatar_name)
    docker_cmd = [
      'docker exec',
      "--user=#{uid}:#{gid}",
      '--interactive',
      cid,
      "sh -c 'cd #{sandbox} && chmod 755 . && sh ./cyber-dojo.sh'"
    ].join(space)

    run_timeout(docker_cmd, max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    # The docker daemon responds to [docker rm] asynchronously...
    # An 'immediately' following old_avatar()'s [docker volume rm]
    # might fail since the container is not quite dead yet.
    # This is unlikely to happen in real use but quite likely in tests.
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

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sandboxes_data_only_container_name(kata_id)
    'cyber_dojo_' + kata_id
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include NearestAncestors
  def log; nearest_ancestors(:log); end

end
