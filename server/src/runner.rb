
module Runner # mix-in

  module_function

  def pulled?(image_name)
    #image_names.include?(image_name)
  end

  def pull(image_name)
    #command = [ sudo, 'docker', 'pull', image_name].join(space).strip
    #_output,_exit_status = shell.exec(command)
  end

  def start(kata_id, avatar_name)
    vol_name = "cyber_dojo_#{kata_id}_#{avatar_name}"
    # command = "sudo ... docker volume create #{vol_name}"
    # shell.exec(command)
  end

  def run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    # 1. Assume volume exists from previous /start
    vol_name = "cyber_dojo_#{kata_id}_#{avatar_name}"

    # 2. Mount the volume into container made from image
    # command= "sudo ... docker create
    #             --interactive
    #             --user=root
    #             --volume=#{vol_name}:/sandbox
    #             #{image_name} sh"
    # cid = shell.exec(command)

    # 3. Start the container
    # sudo ... docker start ${g_cid}

    # 4. Delete deleted_filenames from /sandbox in container
    # delete_filenames.each do |filename|
    #   command = "sudo ... docker exec #{cid} sh -c 'rm /sandbox/#{filename}"
    #   shell.exec(command)
    # end

    # 5. Copy changed_files into /sandbox
    # Dir.mktmpdir('differ') do |tmp_dir|
    #   changed_files.each do |filename, content|
    #     disk[tmp_dir].write(filename, content)
    #   end
    #
    #   ...Is nobody's user-ID must be same in runner image and in #{image_name} ?
    #   ...If so I can chown tmp_dir/* as a single command
    #
    #   command = "sudo ... docker cp #{tmp_dir}/ #{cid}:/sandbox"
    #   shell.exec(command)
    #   changed_files.each do |filename, content|
    #     command="docker exec #{cid} sh -c 'chown -R nobody:nobody /sandbox/#{filename}'"
    #     shell.exec(command)
    #   end
    # end

    # 6. Deletegate to docker_runner.sh
    # args = [ cid, max_seconds, quoted(sudo) ].join(space)
    # output, exit_status = shell.cd_exec(my_dir, "./docker_runner.sh #{args}")

    # 7. Make sure container is deleted
    # command = "sudo ... docker rm -f #{cid}"
    # shell.exec(command)

    # output_or_timed_out(output, exit_status, max_seconds)

    'output'
  end

  private

  #include NearestAncestors
  #include Runner

  def image_names
    # [docker images] must be made by a user that has sufficient rights.
    # See docker/web/Dockerfile
    command = [sudo, 'docker', 'images'].join(space).strip
    output, _ = shell.exec(command)
    # This will (harmlessly) get all cyberdojofoundation image names too.
    lines = output.split("\n").select { |line| line.start_with?('cyberdojo') }
    lines.collect { |line| line.split[0] }
  end

  def disk
    #nearest_ancestors(:disk)
  end

  def shell
    #nearest_ancestors(:shell)
  end

  def sudo
    # See sudo comments in Dockerfile
    'sudo -u docker-runner sudo'
  end

  def quoted(s)
    "'" + s + "'"
  end

  def space
    ' '
  end

end
