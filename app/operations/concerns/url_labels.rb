module UrlLabels
  def self.extract_url_labels(urls)
    visitor = TasksVisitors::ExtractStrings.new
    visitor.visit(urls)
    [urls, visitor.collector]
  end
end
