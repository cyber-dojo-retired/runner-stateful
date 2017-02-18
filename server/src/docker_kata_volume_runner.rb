require_relative 'docker_runner_volume_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per kata.
#
# Positives:
#   o) short-lived container per run() limits
#      fork-bomb escalation.
#   o) container has low pids-limit-16 which further
#      limits fork-bomb escalation.
#   o) avatars can share state (eg sqlite database
#      in /sandboxes/shared)
#
# Negatives:
#   o) avatars cannot share processes.
#   o) bit slower than KataContainerRunner.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerKataVolumeRunner

  include DockerRunnerVolumeMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?
    volume_exists?(kata_volume_name)
  end

  def new_kata
    refute_kata_exists
    create_volume(kata_volume_name)
  end

  def old_kata
    assert_kata_exists
    remove_volume(kata_volume_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      avatar_exists_cid?(cid, avatar_name)
    end
  end

  def new_avatar(avatar_name, starting_files)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      refute_avatar_exists(cid, avatar_name)
      make_shared_dir(cid)
      chown_shared_dir(cid)
      make_sandbox_dir(cid, avatar_name)
      chown_sandbox_dir(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    end
  end

  def old_avatar(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      remove_sandbox_dir(cid, avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which kills
  # kills all processes running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      { stdout:stdout, stderr:stderr, status:status }
    end
  end

  private

  def in_kvr_container(avatar_name, &block)
    volume_name = kata_volume_name
    volume_root = sandboxes_root
    in_container(avatar_name, volume_name, volume_root, &block)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_sandbox_dir(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    mkdir = "mkdir -m 755 #{sandbox}"
    assert_docker_exec(cid, mkdir)
  end

  def remove_sandbox_dir(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    rmdir = "rm -rf #{sandbox}"
    assert_docker_exec(cid, rmdir)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_shared_dir(cid)
    shared_dir = "/sandboxes/shared"
    mkdir = "mkdir -m 775 #{shared_dir} || true" # idempotent
    assert_docker_exec(cid, mkdir)
  end

  def chown_shared_dir(cid)
    shared_dir = "/sandboxes/shared"
    chown = "chown root:cyber-dojo #{shared_dir}"
    assert_docker_exec(cid, chown)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_exists(cid, avatar_name)
    unless avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(cid, avatar_name)
    if avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('exists')
    end
  end

  def avatar_exists_cid?(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    cmd = "docker exec #{cid} sh -c '[ -d #{sandbox} ]'"
    _,_,status = quiet_exec(cmd)
    status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_name
    'cyber_dojo_kata_volume_runner_' + kata_id
  end

end
