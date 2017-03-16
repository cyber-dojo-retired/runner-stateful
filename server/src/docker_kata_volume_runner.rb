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
      make_avatar_dir(cid, avatar_name)
      chown_avatar_dir(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    end
  end

  def old_avatar(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_kvr_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      remove_avatar_dir(cid, avatar_name)
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
    in_container(avatar_name, kata_volume_name, sandboxes_root_dir, &block)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "mkdir -m 755 #{dir}")
  end

  def remove_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "rm -rf #{dir}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_shared_dir(cid)
    # first avatar makes the shared dir
    assert_docker_exec(cid, "mkdir -m 775 #{shared_dir} || true")
  end

  def chown_shared_dir(cid)
    assert_docker_exec(cid, "chown root:#{group} #{shared_dir}")
  end

  def shared_dir
    "#{sandboxes_root_dir}/shared"
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
    dir = avatar_dir(avatar_name)
    _,_,status = quiet_exec("docker exec #{cid} sh -c '[ -d #{dir} ]'")
    status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_name
    'cyber_dojo_kata_volume_runner_' + kata_id
  end

end
