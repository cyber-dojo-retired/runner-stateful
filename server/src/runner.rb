
def runner_class_name(image_name)
  class_name ||= 'SharedContainerRunner' if container_runner?(image_name)
  class_name ||= 'SharedVolumeRunner'    if volume_runner?(image_name)
  class_name ||= 'SharedVolumeRunner'    # default
  autoload(:SharedContainerRunner, '/app/src/shared_container_runner.rb') if class_name == 'SharedContainerRunner'
  autoload(:SharedVolumeRunner,    '/app/src/shared_volume_runner.rb')    if class_name == 'SharedVolumeRunner'
  class_name
end

def volume_runner?(image_name)
  tagless(image_name).end_with?('shared_disk')
end

def container_runner?(image_name)
  tagless(image_name).end_with?('shared_process')
end

def tagless(image_name)
  o = split_image_name(image_name)
  o[:name]
end

def split_image_name(image_name)
  # http://stackoverflow.com/questions/37861791
  i = image_name.index('/')
  if i.nil? || i == -1 || (
      !image_name[0...i].include?('.') &&
      !image_name[0...i].include?(':') &&
       image_name[0...i] != 'localhost')
    hostname = ''
    remote_name = image_name
  else
    hostname = image_name[0..i-1]
    remote_name = image_name[i+1..-1]
  end

  alpha_numeric = '[a-z0-9]+'
  separator = '([.]{1}|[_]{1,2}|[-]+)'
  component = "#{alpha_numeric}(#{separator}#{alpha_numeric})*"
  name = "#{component}(/#{component})*"
  tag = '[\w][\w.-]{0,126}'
  md = /^(#{name})(:(#{tag}))?$/.match(remote_name)

  fail ArgumentError.new('image_name:invalid') if md.nil?

  {
    hostname:hostname,
    name:md[1],
    tag:md[8] || ''
  }
end

module Runner # mix-in

  def runner
    new_runner(image_name, kata_id)
  end

  def new_runner(image_name, kata_id)
    Object.const_get(runner_class_name(image_name)).new(self, image_name, kata_id)
  end

end
