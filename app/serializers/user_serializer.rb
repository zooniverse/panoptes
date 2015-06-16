class UserSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  include MediaLinksSerializer

  attributes :id, :login, :display_name, :credited_name, :email, :created_at,
    :updated_at, :type, :firebase_auth_token, :global_email_communication,
    :project_email_communication, :beta_email_communication,
    :max_subjects, :uploaded_subjects_count, :admin

  can_include :classifications, :project_preferences, :collection_preferences,
    projects: { param: "owner", value: "login" },
    collections: { param: "owner", value: "login" }

  media_include :avatar, :profile_header

  def credited_name
    @model.credited_name
  end

  def email
    @model.email
  end

  def global_email_communication
    @model.global_email_communication
  end

  def project_email_communication
    @model.project_email_communication
  end

  def beta_email_communication
    @model.beta_email_communication
  end

  def firebase_auth_token
    FirebaseUserToken.generate(@model)
  end

  def max_subjects
    Panoptes.max_subjects
  end

  def uploaded_subjects_count
    @model.uploaded_subjects_count
  end

  def admin
    !!@model.admin
  end

  def type
    "users"
  end

  private

  def permitted_requester?
    @permitted ||= @context[:include_private] || requester
  end

  %w(credited_name email global_email_communication project_email_communication
     beta_email_communication uploaded_subjects_count max_subjects admin).each do |me_only_attribute|
    alias_method :"include_#{me_only_attribute}?", :permitted_requester?
  end

  def requester
    @context[:requester] && @context[:requester].logged_in? &&
      (@context[:requester].is_admin? || requester_is_user?)
  end

  def requester_is_user?
    @model.id == @context[:requester].id
  end

  def include_firebase_auth_token?
    @context[:include_firebase_token] && requester_is_user?
  end

  def add_links(model, data)
    data[:links] = {}
  end
end
