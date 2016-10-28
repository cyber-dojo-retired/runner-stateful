require 'minitest/autorun'

class HexMiniTest < MiniTest::Test

  @@args = (ARGV.sort.uniq - ['--']).map(&:upcase) # eg 2E4
  @@seen_hex_ids = []

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.test(hex_suffix, *lines, &test_block)
    validate_hex_prefix
    validate_hex_id(hex_suffix, lines)
    hex_id = hex_prefix + hex_suffix
    @@seen_hex_ids << hex_id
    if @@args == [] || @@args.any?{ |arg| hex_id.include?(arg) }
      execute_around = lambda {
        _hex_setup_caller(hex_id)
        begin
          self.instance_eval &test_block
        ensure
          _hex_teardown_caller
        end
      }
      proposition = lines.join(space = ' ')
      name = "hex '#{hex_suffix}',\n'#{proposition}'"
      define_method("test_\n#{name}".to_sym, &execute_around)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.validate_hex_prefix
    method = 'def self.hex_prefix'
    pointer = ' ' * method.index('.') + '!'
    pointee = (['',pointer,method,'','']).join("\n")
    fail "\n\n#{pointer}missing#{pointee}" unless self.respond_to?(:hex_prefix)
    fail "\n\n#{pointer}empty#{pointee}" if hex_prefix == ''
    fail "\n\n#{pointer}not hex#{pointee}" unless hex_prefix =~ /^[0-9A-F]+$/
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.validate_hex_id(hex_suffix, lines)
    method = "test '#{hex_suffix}',"
    proposition = lines.join(space = ' ')
    pointer = ' ' * method.index("'") + '!'
    pointee = ['',pointer,method,"'#{proposition}'",'',''].join("\n")
    hex_id = hex_prefix + hex_suffix
    fail "\n\n#{pointer}empty#{pointee}" if hex_suffix == ''
    fail "\n\n#{pointer}not hex#{pointee}" unless hex_suffix =~ /^[0-9A-F]+$/
    fail "\n\n#{pointer}duplicate#{pointee}" if @@seen_hex_ids.include?(hex_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def _hex_setup_caller(hex_id)
    @config = {}
    env_map.keys.each { |key| @config[key] = ENV[key] }
    @_hex_test_id = hex_id
    hex_setup
  end

  def _hex_teardown_caller
    hex_teardown
  ensure
    env_map.keys.each { |key| ENV[key] = @config[key] }
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def hex_setup; end
  def hex_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - -

  def test_id
    @_hex_test_id
  end

end
