require_relative './snake_caser'

# Sets defauls ENV-vars for all externals.
# Unit-tests can set/reset these.
# See test/external_helper.rb

def env_name(suffix)
  'RUNNER_CLASS_' + suffix.upcase
end

def env_map
  {
    env_name('disk')  => 'ExternalDiskWriter',
    env_name('log')   => 'ExternalStdoutLogger',
    env_name('shell') => 'ExternalSheller'
  }
end

env_map.each do |key,name|
  ENV[key] = name
  require_relative "./#{name.snake_cased}"
end
