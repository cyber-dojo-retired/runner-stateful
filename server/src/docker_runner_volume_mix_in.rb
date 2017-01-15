require_relative 'docker_runner_mix_in'

module DockerRunnerVolumeMixIn

  include DockerRunnerMixIn

  module_function # = = = = = = = = = = = = = = = =

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

end

