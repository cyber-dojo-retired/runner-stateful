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
        _secret_hex_setup(hex_id)
        begin
          self.instance_eval &test_block
        ensure
          _secret_hex_teardown
        end
      }
      proposition = lines.join(space = ' ')
      name = "hex '#{hex_suffix}',\n'#{proposition}'"
      define_method("test_\n#{name}".to_sym, &execute_around)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def _secret_hex_setup(hex_id)
    @_secret_test_id = hex_id
    @config = {}
    env_map.keys.each { |key| @config[key] = ENV[key] }
    hex_setup
  end

  def test_id
    @_secret_test_id
  end

  def _secret_hex_teardown
    hex_teardown
  ensure
    env_map.keys.each { |key| ENV[key] = @config[key] }
  end

  def hex_setup; end
  def hex_teardown; end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.validate_hex_prefix
    spacer = "\n\n         !"
    diagnostic = [
      '',
      '         !',
      "def self.hex_prefix",
      '',
      ''
    ].join("\n")

    fail "#{spacer}missing#{diagnostic}" unless self.respond_to?(:hex_prefix)
    fail "#{spacer}empty#{diagnostic}" if hex_prefix == ''
    fail "#{spacer}not hex#{diagnostic}" unless hex_prefix =~ /^[0-9A-F]+$/
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def self.validate_hex_id(hex_suffix, lines)
    proposition = lines.join(space = ' ')
    spacer = "\n\n      !"
    diagnostic = [
      '',
      '      !',
      "test '#{hex_suffix}',",
      "'#{proposition}'",
      '',
      ''
    ].join("\n")
    hex_id = hex_prefix + hex_suffix
    fail "#{spacer}empty#{diagnostic}" if hex_suffix == ''
    fail "#{spacer}not hex#{diagnostic}" unless hex_suffix =~ /^[0-9A-F]+$/
    fail "#{spacer}duplicate#{diagnostic}" if @@seen_hex_ids.include?(hex_id)
  end

end
