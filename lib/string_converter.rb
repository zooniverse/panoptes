module StringConverter

  def self.replace_spaces(string)
    return nil unless string.is_a?(String)
    string.gsub(/\s+/, '_')
  end
end
