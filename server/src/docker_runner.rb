
module DockerRunner # mix-in

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def pull(image_name)
    assert_exec("docker pull #{image_name}")
  end

  module_function

  def image_names
    cmd = 'docker images --format "{{.Repository}}"'
    stdout,_ = assert_exec(cmd)
    names = stdout.split("\n")
    names.uniq - ['<none']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def alpine?(kata_id)
    etc_issue(kata_id).include?('Alpine')
  end

  def ubuntu?(kata_id)
    etc_issue(kata_id).include?('Ubuntu')
  end

  def etc_issue(kata_id)
    stdout,_ = assert_docker_exec(kata_id, 'cat /etc/issue')
    stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(kata_id, cmd)
    assert_exec(docker_cmd(kata_id, cmd))
  end

  def docker_cmd(kata_id, cmd)
    cid = container_name(kata_id)
    "docker exec #{cid} sh -c '#{cmd}'"
  end

  def assert_exec(cmd)
    stdout,stderr,status = exec(cmd)
    unless status == success
      fail_command(cmd)
    end
    [stdout,stderr]
  end

  def exec(cmd, logging = @logging)
    shell.exec(cmd, logging)
  end

end

