module StringConverter

  def self.downcase_and_replace_spaces(string)
    return nil unless string.is_a?(String)
    string.downcase.gsub(/\s/, '_')
  end
end
