
def runner_class_name(image_name)
  class_name ||= 'SharedContainerRunner' if container_runner?(image_name)
  class_name ||= 'SharedVolumeRunner'    if volume_runner?(image_name)
  class_name ||= 'SharedVolumeRunner'    # default
  autoload(:SharedContainerRunner, '/app/src/shared_container_runner.rb') if class_name == 'SharedContainerRunner'
  autoload(:SharedVolumeRunner,    '/app/src/shared_volume_runner.rb')    if class_name == 'SharedVolumeRunner'
  class_name
end

def volume_runner?(image_name)
  tagless(image_name).end_with?(':shared_disk')
end

def container_runner?(image_name)
  tagless(image_name).end_with?(':shared_process')
end

def tagless(image_name)
  # http://stackoverflow.com/questions/37861791/
  # https://github.com/docker/docker/blob/master/image/spec/v1.1.md
  # Simplified, no hostname
  alpha_numeric = '[a-z0-9]+'
  separator = '[_.-]+'
  component = "#{alpha_numeric}(#{separator}#{alpha_numeric})*"
  name = "#{component}(/#{component})*"
  tag = '[\w][\w.-]{0,127}'
  md = /^(#{name})(:#{tag})?$/o.match(image_name)
  return image_name if md.nil?
  md[1]
end

module Runner # mix-in

  def runner
    new_runner(image_name, kata_id)
  end

  def new_runner(image_name, kata_id)
    Object.const_get(runner_class_name(image_name)).new(self, image_name, kata_id)
  end

end
