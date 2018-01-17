require 'model_version'

class Api::V1::WorkflowsController < Api::ApiController
  include Versioned
  include TranslatableResource
  include MediumResponse

  require_authentication :update, :create, :destroy, :retire_subjects, :create_classifications_export, scopes: [:project]

  resource_actions :index, :show, :create, :update, :deactivate
  schema_type :json_schema

  prepend_before_action :require_login, only: [:create, :update, :destroy, :create_classifications_export]
  prepend_before_action :available_to_export, only: :create_classifications_export

  def index
    unless params.has_key?(:sort)
      @controlled_resources = controlled_resources.rank(:display_order)
    end
    super
  end

  def update
    super do |resource|
      if update_params.key? :tasks
        _, strings = extract_strings(update_params[:tasks])
        resource.primary_content.update(strings: strings)
      end
    end
  end

  def update_links
    super do |workflow|
      UnfinishWorkflowWorker.perform_async(workflow.id)
      WorkflowRetiredCountWorker.perform_async(workflow.id)
      post_link_actions(workflow)
    end
  end

  def destroy_links
    super { |workflow| post_link_actions(workflow) }
  end

  def retire_subjects
    operation.with(workflow: controlled_resource).run!(params)
    render nothing: true, status: 204
  end

  def create_classifications_export
    medium = CreateClassificationsExport.with( api_user: api_user, object: controlled_resource ).run!(params)
    medium_response(medium)
  end

  private

  def context
    case action_name
    when "show", "index"
      { languages: current_languages }.merge field_context
    else
      {}
    end
  end

  def field_context
    if params[:fields].present?
      included_keys = params[:fields].split(',')
      attrs = WorkflowSerializer.serializable_attributes.with_indifferent_access
      allowed_keys = attrs.slice(*included_keys).keys | ['id']
      excluded_fields = attrs.keys - allowed_keys
      { }.tap do |attributes|
        excluded_fields.each do |field|
          attributes[:"include_#{ field }?"] = false
        end
      end
    else
      { }
    end
  end

  # This is a very good reason to move away from the api controller work we've got
  # it's hard to hook into the right place to run actions that in theory should
  # be easily located in specific controller actions
  def post_link_actions(workflow)
    if workflow.set_member_subjects.exists?
      case relation
      when :retired_subjects, 'retired_subjects'
        params[:retired_subjects].each do |subject_id|
          NotifySubjectSelectorOfRetirementWorker.perform_async(subject_id, workflow.id)
        end
      when :subject_sets, 'subject_sets'
        CalculateProjectCompletenessWorker.perform_async(workflow.project_id)
        NotifySubjectSelectorOfChangeWorker.perform_async(workflow.id)
      end
    end
  end

  def build_update_hash(update_params, resource)
    if update_params.key? :tasks
      stripped_tasks, strings = extract_strings(update_params[:tasks])
      update_params[:tasks] = stripped_tasks
    end

    reject_live_project_changes(resource, update_params)
    super(update_params, resource)
  end

  def build_resource_for_create(create_params)
    stripped_tasks, strings = extract_strings(create_params[:tasks])
    create_params[:tasks] = stripped_tasks
    create_params[:active] = false if project_live?
    workflow = super(create_params)
    workflow.workflow_contents.build(
      strings: strings,
      language: workflow.primary_language
    )
    workflow
  end

  def extract_strings(tasks)
    return @task_strings if @task_strings
    task_string_extractor = TasksVisitors::ExtractStrings.new
    task_string_extractor.visit(tasks)
    @task_strings = [tasks, task_string_extractor.collector]
  end

  def add_relation(resource, relation, value)
    if relation == :retired_subjects && value.is_a?(Array)
      resource.save!
      value.each {|id| resource.retire_subject(id) }
      resource.reload
    else
      super
    end
  end

  def new_items(resource, relation, value)
    case relation
    when :retired_subjects, 'retired_subjects'
      resource.save!
      value.flat_map {|id| resource.retire_subject(id) }
      resource.reload
    when :subject_sets, 'subject_sets'
      items = construct_new_items(super(resource, relation, value), resource.project_id)
      if items.any? { |item| item.is_a?(SubjectSet) }
        items
      else
        items.first
      end
    else
      super
    end
  end

  def construct_new_items(item_scope, workflow_project_id)
    Array.wrap(item_scope).map do |item|
      if item.is_a?(SubjectSet) && !item.belongs_to_project?(workflow_project_id)
        SubjectSetCopier.new(item, workflow_project_id).duplicate_subject_set_and_subjects
      else
        item
      end
    end
  end

  def reject_live_project_changes(workflow, update_hash)
    if workflow.active && workflow.project.live && non_permitted_changes?(workflow, update_hash)
      raise Api::LiveProjectChanges.new("Can't change an active workflow for a live project.")
    end
  end

  def non_permitted_changes?(workflow, hash)
    %i(tasks grouped prioritized pairwise first_task).any? do |field|
      if hash.has_key? field
        !(workflow.send(field) == hash[field])
      else
        false
      end
    end
  end

  def project_live?
    project_from_params.try(:live)
  end

  def project_from_params
    project_id = params_for[:links].try(:[], :project)
    if project_id && project = Project.find_by(id: project_id)
      project
    end
  end

  def assoc_class(relation)
    case relation
    when :retired_subjects, "retired_subjects"
      SubjectWorkflowStatus
    else
      super
    end
  end

  def available_to_export
    if controlled_resource.project.disabled_data_export?
      raise Api::DisabledDataExport.new(
        "Data exports are disabled for this project"
      )
    end
  end
end
