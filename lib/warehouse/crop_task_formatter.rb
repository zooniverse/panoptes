module Warehouse
  class CropTaskFormatter < BasicTaskFormatter
    def value(annotation)
      annotation.fetch("value").to_json
    end
  end
end
