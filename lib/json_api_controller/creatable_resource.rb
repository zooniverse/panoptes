module JsonApiController
  module CreatableResource
    include RelationManager

    def create
      resources = ActiveRecord::Base.transaction(requires_new: true) do
        begin
          Array.wrap(create_params).map do |ps|
            resource = build_resource_for_create(ps)
            resource.save!
            resource
          end
        end
      end

      created_resource_response(resources)
    end

    protected

    def add_user_as_linked_owner(create_params)
      unless create_params.fetch(:links, {}).has_key? :owner
        create_params[:links] ||= {}
        create_params[:links][:owner] = api_user.user
      end
    end

    def build_resource_for_create(create_params)
      link_params = create_params.delete(:links)
      if block_given?
        yield create_params, link_params
      end
      resource = resource_class.new(create_params)

      link_params.try(:each) do |k,v|
        #http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-has_one
        # association=(associate)
        #   Assigns the associate object, extracts the primary key, sets it as the foreign key,
        #   and saves the associate object. To avoid database inconsistencies, permanently
        #   deletes an existing associated object when assigning a new one, even if the
        #   new one isn't saved to database.
        #
        # Using the setter here on a has_one saves the relation outside of the
        # create transaction above when building for create action
        # we want to build the relation set and not have any autosave behind the scences
        # It's ok when updating each relation already exists, if not then we'll need
        # similar behaviour to the build action.

        # The caveat being we'd have to reflect on each relation noting that a has_one :through
        # builds differently and i haven't gotten the owner relation building properly
        # via the owner_control_list.
        resource.send("#{k}=", update_relation(resource, k,v))
      end

      resource
    end

    def create_response(resource)
      serializer.resource({}, resource_scope(resource), context)
    end

    def link_header(resource)
      send(:"api_#{ resource_name }_url", resource)
    end
  end
end
