module Warehouse
  class TextTaskFormatter < BasicTaskFormatter
    def value(annotation)
      annotation.fetch("value").to_s
    end
  end
end
