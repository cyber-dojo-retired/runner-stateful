require_relative 'docker_runner_volume_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per avatar.
#
# Positives:
#   o) short-lived container per run() limits
#      fork-bomb escalation.
#   o) container has low pids-limit-16 which further
#      limits fork-bomb escalation.
#
# Negatives:
#   o) no possibility of avatars sharing state or processes.
#   o) increased run() time
#      (compared to one container per kata)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerAvatarVolumeRunner

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
    volume_exists?(avatar_volume_name(avatar_name))
  end

  def new_avatar(avatar_name, starting_files)
    assert_kata_exists
    refute_avatar_exists(avatar_name)

    create_volume(avatar_volume_name(avatar_name))
    in_avr_container(avatar_name) do |cid|
      chown_sandbox_dir(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    end
  end

  def old_avatar(avatar_name)
    assert_kata_exists
    assert_avatar_exists(avatar_name)
    remove_volume(avatar_volume_name(avatar_name))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which kills
  # all processes running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_avatar_exists(avatar_name)

    in_avr_container(avatar_name) do |cid|
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      { stdout:stdout, stderr:stderr, status:status }
    end
  end

  private

  def in_avr_container(avatar_name, &block)
    volume_name = avatar_volume_name(avatar_name)
    volume_root_dir = sandbox_dir(avatar_name)
    in_container(avatar_name, volume_name, volume_root_dir, &block)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_exists(avatar_name)
    unless avatar_exists?(avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(avatar_name)
    if avatar_exists?(avatar_name)
      fail_avatar_name('exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_name
    'cyber_dojo_avatar_volume_runner_kata_' + kata_id
  end

  def avatar_volume_name(avatar_name)
    'cyber_dojo_avatar_volume_runner_avatar_' + kata_id + '_' + avatar_name
  end

end
