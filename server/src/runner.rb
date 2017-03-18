
def runner_class_name
  'DockerVolumeRunner'
  #'DockerContainerRunner'
end

require_relative 'snake_caser'
require_relative SnakeCaser::snake_cased(runner_class_name)

module Runner # mix-in

  def runner
    # if image_name.end_with?(':DockerContainerRunner')
    #   DockerContainerRunner.new(self, image_name, kata_id)
    # else
    #   DockerVolumeRunner.new(self, image_name, kata_id)
    Object.const_get(runner_class_name).new(self, image_name, kata_id)
  end

end
