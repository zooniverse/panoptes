module Generic
  class UpdateLinks < Operation
    object :resource, class: :Object
    hash :params, strip: false

    def execute
      resource.class.transaction(requires_new: true) do
        add_relation(resource, relation, params[relation])
        resource.save!
      end
    end

    private

    def add_relation(resource, relation, value)
      if relation == :retired_subjects && value.is_a?(Array)
        resource.save!
        value.each {|id| resource.retire_subject(id) }
        resource.reload
      else
        super
      end
    end

    def relation
      params[:link_relation].to_sym
    end
  end
end
