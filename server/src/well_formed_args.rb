require_relative 'base58'
require_relative 'well_formed_image_name'
require 'json'

# Checks for arguments synactic correctness

class WellFormedArgs

  def initialize(s)
    @args = JSON.parse(s)
    if @args.nil? || !@args.is_a?(Hash)
      malformed('json')
    end
  rescue
    malformed('json')
  end

  # - - - - - - - - - - - - - - - -

  def image_name
    name = __method__.to_s
    arg = @args[name]
    unless well_formed_image_name?(arg)
      malformed(name)
    end
    arg
  end

  # - - - - - - - - - - - - - - - -

  def kata_id
    name = __method__.to_s
    arg = @args[name]
    unless well_formed_kata_id?(arg)
      malformed(name)
    end
    arg
  end

  # - - - - - - - - - - - - - - - -

  def starting_files
    well_formed_files(__method__)
  end

  def new_files
    well_formed_files(__method__)
  end

  def deleted_files
    well_formed_files(__method__)
  end

  def unchanged_files
    well_formed_files(__method__)
  end

  def changed_files
    well_formed_files(__method__)
  end

  # - - - - - - - - - - - - - - - -

  def max_seconds
    name = __method__.to_s
    arg = @args[name]
    unless well_formed_max_seconds?(arg)
      malformed(name)
    end
    arg
  end

  private # = = = = = = = = = = = =

  include WellFormedImageName

  def well_formed_kata_id?(arg)
    Base58.string?(arg) && arg.size == 10
  end

  def well_formed_files(name)
    name = name.to_s
    arg = @args[name]
    unless arg.is_a?(Hash) && arg.all? { |k,v| k.is_a?(String) && v.is_a?(String) }
      malformed(name)
    end
    arg
  end

  def well_formed_max_seconds?(arg)
    arg.is_a?(Integer) && (1..20).include?(arg)
  end

  # - - - - - - - - - - - - - - - -

  def malformed(arg_name)
    raise ArgumentError.new("#{arg_name}:malformed")
  end

end