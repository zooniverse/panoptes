module AdminAllowed
  extend ActiveSupport::Concern

  def admin_allowed(action_params, *parameters)
    parameters.each do |param|
      if action_params.has_key?(param) && !api_user.is_admin?
        raise Api::UnpermittedParameter, "Only Admins may set field #{param} for #{resource_name}"
      end
    end
  end
end
