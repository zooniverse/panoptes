module IndexSearch
  extend ActiveSupport::Concern

  included do
    before_action :search, only: :index, if: :search_query?
    @search_handlers ||= {}.with_indifferent_access
  end

  module ClassMethods
    def search_by(criteria=:default, &block)
      @search_handlers[criteria] ||= []
      @search_handlers[criteria] << block
    end
  end

  def search
    search_query = applicable_filters.reduce(controlled_resources) do |query, (criteria, blocks)|
      blocks.reduce(query){ |q, block| block.call(search_criteria[criteria], q) }
    end
    @controlled_resources = search_query
  end

  def applicable_filters
    search_handlers.select{ |criteria,_| !search_criteria[criteria].blank? }
  end

  def search_criteria
    @search_criteria ||= search_params.split(" ").reduce({default: []}.with_indifferent_access) do |accum, term|
      key, value = term.split(":")
      if value
        accum[key] ||= []
        accum[key] << value
      else
        accum[:default] << key
      end
      accum
    end
  end

  def search_params
    params.fetch(:search, "")
  end

  def search_handlers
    self.class.instance_variable_get(:@search_handlers)
  end

  def search_query?
    params.has_key?(:search)
  end
end
