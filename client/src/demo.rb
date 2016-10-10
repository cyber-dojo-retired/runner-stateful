require 'sinatra'
require 'sinatra/base'

require_relative './runner'

class Demo < Sinatra::Base

  get '/' do

    # start

    image_name = 'cyberdojofoundation/gcc_assert'
    kata_id = 'D4C8A65D61'
    avatar_name = 'lion'
    max_seconds = 10
    delete_filenames = []
    changed_files = {
      'cyber-dojo.sh': "blah blah blah",
      'hiker.c': '#include "hiker.h"',
      'hiker.h': "#ifndef HIKER_INCLUDED\n#endif",
      'compacted.eg':
        [ "def finalize(values)",
          "",
          "  values.each do |v|",
          "    v.prepare",
          "  end",
          "",
          "  values.each do |v|",
          "    v.finalize",
          "  end",
          "",
          "end"
        ].join("\n")
    }
    json = run(image_name, kata_id, avatar_name, max_seconds, delete_filenames, changed_files)
    '<pre>' + JSON.pretty_unparse(json) + '</pre>'
  end

  include Runner

end


