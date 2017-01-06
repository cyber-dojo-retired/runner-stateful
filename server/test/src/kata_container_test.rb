require_relative 'test_base.rb'

class KataContainerTest < TestBase

  def self.hex_prefix; '6ED'; end

  def self.kc_test(hex_suffix, *lines, &test_block)
    if runner_class == 'DockerKataContainerRunner'
      test(hex_suffix, *lines, &test_block)
    end
  end

  kc_test '5F9',
  'only run if runner is DockerKataContainerRunner' do
    #puts "RUNNING THIS TEST"
  end

end
