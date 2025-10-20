module Segregato
  module Error
    class StrictWriteModelError < StandardError
      def initialize(method)
        super("The Write Model is not allowed to perform the Read operation: #{method}")
      end
    end

    class StrictReadModelError < StandardError
      def initialize(method)
        super("The Read Model is not allowed to perform Write operations: #{method}")
      end
    end
  end
end