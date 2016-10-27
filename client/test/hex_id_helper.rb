
# Uses a hex-id on each test to selectively run specific tests.
# A good way to generate unique hex-ids is uuidgen.
# Write your test methods as follows:
#
#    class SomeTest < MiniTest::Test
#
#      include TestHexIdHelpers
#
#      test '0C1F2F',
#      'some long description',
#      'possibly spanning',
#      'several lines' do
#        ...
#        ...
#        ...
#      end
#
#    end

module TestHexIdHelper # mix-in

  def self.included(base)
    base.extend(ClassMethods)
  end

  def test_id
    ENV['TEST_ID']
  end

  module ClassMethods

    @@args = (ARGV.sort.uniq - ['--']).map(&:upcase)  # eg 2DD6F3 eg 2dd
    @@seen_ids = []

    def test(tid, *lines, &block)
      fail 'missing hex()' unless self.respond_to?(:hex)
      id = hex + tid
      diagnostic = "'#{id}',#{lines.join}"
      fail "duplicate hex_ID: #{diagnostic}" if @@seen_ids.include?(id)
      @@seen_ids << id
      # check hex-id is well-formed
      hex_chars = '0123456789ABCDEF'
      is_hex_id      = id.chars.all? { |ch| hex_chars.include? ch }
      has_empty_line = lines.any?    { |line| line.strip == ''    }
      has_space_line = lines.any?    { |line| line.strip != line  }
      fail  "no hex-ID: #{diagnostic}" if id == ''
      fail "bad hex-ID: #{diagnostic}" unless is_hex_id
      fail "empty line: #{diagnostic}" if has_empty_line
      fail "space line: #{diagnostic}" if has_space_line
      # if no hex-id supplied, or test method matches any
      # supplied hex-id then define a mini_test method
      run_all = @@args == []
      any_arg_is_part_of_id = @@args.any?{ |arg| id.include?(arg) }
      if run_all || any_arg_is_part_of_id
        block_with_test_id = lambda {
          ENV['TEST_ID'] = id # make available inside test
          puts ">>>>>> #{id} <<<<<<" if any_arg_is_part_of_id
          self.instance_eval &block
        }
        name = lines.join(' ')
        define_method("test_'#{id}',\n #{name}\n".to_sym, &block_with_test_id)
      end
    end

  end

end
