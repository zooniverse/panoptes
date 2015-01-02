module RoleControl
  class AccessDenied < StandardError; end
  
  module RoledController
    extend ActiveSupport::Concern

    DEFAULT_ACCESS_CONTROL_ACTIONS = %i(update show index destroy update_links destory_links)

    module ClassMethods
      def setup_access_control_for_user!(*actions)
        actions = DEFAULT_ACCESS_CONTROL_ACTIONS if actions.blank?
        setup_access_control!(*actions) { |user| user }
      end

      def setup_access_control_for_groups!(*actions)
        actions = DEFAULT_ACCESS_CONTROL_ACTIONS if actions.blank?
        setup_access_control!(*actions) do |user, action, klass|
          user.groups_for(action, klass).try(:select, :id)
        end
      end
      
      def setup_access_control!(*actions, &block)
        define_method(:controlled_block) { block }
        before_action only: actions do |controller|
          unless controller.controlled_resources.exists?
            raise RoleControl::AccessDenied, send(:rejected_message)
          end
        end
      end
    end

    protected

    def controlled_resources
      @controlled_resources ||= api_user
                              .do(action_name.to_sym, &controlled_block)
                              .to(resource_class, scope_context)
                              .with_ids(resource_ids)
                              .scope
    end

    def rejected_message
      if resource_ids.length == 1
        "Could not find #{resource_name} with id='#{resource_ids.first}'"
      else
        "Could not find #{resource_sym} with ids='#{resource_ids.join(',')}'"
      end
    end

    def resource_ids
      @resource_ids =
        if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
          params["#{ resource_name }_id"]
        elsif params.has_key?(:id)
          params[:id]
        else
          ''
        end.split(',')
    end

    def scope_context
      {}
    end
  end
end
