require_relative './external_disk_writer'
require_relative './external_sheller'
require_relative './external_stdout_logger'

module Externals

  def shell; @shell ||= ExternalSheller.new(self); end
  def  disk;  @disk ||= ExternalDiskWriter.new(self); end
  def   log;   @log ||= ExternalStdoutLogger.new(self); end

end

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# How does Externals work? How are they designed to be used?
#
# 1. include Externals in your top-level scope.
#
#    require_relative './externals'
#    class MicroService < Sinatra::Base
#      ...
#      private
#      include Externals
#      def runner; DockerRunner.new(self); end
#      ...
#    end
#
# 2. All child objects have access to their parent
#    and gain access to the externals via nearest_external()
#
#    require_relative './nearest_external'
#    class DockerRunner
#      def initialize(parent)
#        @parent = parent
#      end
#      attr_reader :parent
#      ...
#      private
#      include NearestExternal
#      def log; nearest_external(:log); end
#      ...
#    end
#
# 3. In tests you can simply set the external directly.
#    Note that Externals.log uses ||=
#
#    class ExampleTest < MiniTest::Test
#      def test_something
#        @log = SpyLogger.new(...)
#        runner = DockerRunner.new(self)
#        runner.do_something
#        assert_equal 'expected', @log.spied
#      end
#    end
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
