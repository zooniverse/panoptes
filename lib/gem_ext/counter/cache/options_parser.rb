Counter::Cache::OptionsParser.class_eval do
  def wait(source_object)
    wait = options[:wait]
    if wait.respond_to?(:call)
      wait.call(source_object)
    else
      wait || 10.seconds
    end
  end
end
