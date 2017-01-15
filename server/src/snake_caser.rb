
module SnakeCaser # mix-in

  module_function

  def snake_cased(s)
    s.gsub(/(.)([A-Z])/,'\1_\2').downcase
  end

end
