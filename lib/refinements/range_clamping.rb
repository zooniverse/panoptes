module Refinements
  module RangeClamping
    refine Range do
      def clamp(value)
        if value < min
          min
        elsif value > max
          max
        else
          value
        end
      end
    end
  end
end
