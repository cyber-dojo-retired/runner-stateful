
def volume_runner?(image_name)
  !image_name.end_with?(':DockerContainerRunner')
end

def container_runner?(image_name)
  image_name.end_with?(':DockerContainerRunner')
end

def runner_class_name(image_name)
  autoload(:DockerContainerRunner, '/app/src/docker_container_runner.rb') if container_runner?(image_name)
  autoload(:DockerVolumeRunner,    '/app/src/docker_volume_runner.rb')    if volume_runner?(image_name)
  class_name = 'DockerContainerRunner' if container_runner?(image_name)
  class_name = 'DockerVolumeRunner'    if volume_runner?(image_name)
  class_name
end

#require_relative 'snake_caser'
#require_relative SnakeCaser::snake_cased(runner_class_name)

module Runner # mix-in

  def runner
    Object.const_get(runner_class_name(image_name)).new(self, image_name, kata_id)
  end

end
