class Api::V1::WorkflowsController < Api::ApiController
  include Versioned
  include TranslatableResource

  doorkeeper_for :update, :create, :destroy, scopes: [:project]

  resource_actions :default
  schema_type :json_schema

  def show
    load_queue
    super
  end

  def create
    super { |workflow| refresh_queue(workflow) }
  end

  def update
    super { |workflow| refresh_queue(workflow) }
  end

  def update_links
    super { |workflow| refresh_queue(workflow) }
  end

  def destroy_links
    super { |workflow| refresh_queue(workflow) }
  end

  private

  def context
    case action_name
    when "show", "index"
      { languages: current_languages }
    else
      {}
    end
  end

  def refresh_queue(workflow)
    ReloadNonLoggedInQueueWorker.perform_async(workflow.id) if workflow.set_member_subjects.exists?
  end

  def load_queue
    EnqueueSubjectQueueWorker.perform_async(params[:id], api_user.id)
  end

  def build_update_hash(update_params, id)
    workflow = Workflow.find(id)
    WorkflowContent.transaction(requires_new: true) do
      if update_params.has_key? :tasks
        stripped_tasks, strings = extract_strings(update_params[:tasks])
        update_params[:tasks] = stripped_tasks
        workflow.primary_content.update(strings: strings)
      end
      reject_live_project_changes(workflow, update_params)
    end
    super(update_params, id)
  end

  def build_resource_for_create(create_params)
    stripped_tasks, strings = extract_strings(create_params[:tasks])
    create_params[:tasks] = stripped_tasks
    create_params[:active] = false if project_live?
    workflow = super(create_params)
    workflow.workflow_contents.build(strings: strings,
                                     language: workflow.primary_language)
    workflow
  end

  def extract_strings(tasks)
    task_string_extractor = TasksVisitors::ExtractStrings.new
    task_string_extractor.visit(tasks)
    [tasks, task_string_extractor.collector]
  end

  def new_items(resource, relation, value)
    items = construct_new_items(super(resource, relation, value), resource.project_id)
    if items.any? { |item| item.is_a?(SubjectSet) }
      items
    else
      items.first
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
end
