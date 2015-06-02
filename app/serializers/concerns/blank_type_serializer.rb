module BlankTypeSerializer

  def self.default_value(value)
    case value
    when Fixnum
      0
    else
      ""
    end
  end
end
