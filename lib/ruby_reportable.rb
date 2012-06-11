unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'ruby_reportable/base'
require_relative 'ruby_reportable/filter'
require_relative 'ruby_reportable/sandbox'
require_relative 'ruby_reportable/source'

require_relative 'ruby_reportable/report'



