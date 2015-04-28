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
    ReloadQueueWorker.perform_async(workflow.id) if workflow.set_member_subjects.exists?
  end

  def load_queue
    SubjectQueueWorker.perform_async(params[:id], api_user.id)
  end

  def build_update_hash(update_params, id)
    if update_params.has_key? :tasks
      stripped_tasks, strings = extract_strings(update_params[:tasks])
      update_params[:tasks] = stripped_tasks
      Workflow.find(id).primary_content.update_attributes(strings: strings)
    end
    super(update_params, id)
  end

  def build_resource_for_create(create_params)
    stripped_tasks, strings = extract_strings(create_params[:tasks])
    create_params[:tasks] = stripped_tasks
    workflow = super(create_params)
    workflow.expert_subject_sets.build(project: workflow.project,
                                       display_name: "Expert Set for #{workflow.display_name}",
                                       expert_set: true)
    workflow.workflow_contents.build(strings: strings,
                                     language: workflow.primary_language)
    workflow
  end

  def extract_strings(tasks)
    task_string_extractor = TasksVisitors::ExtractStrings.new
    task_string_extractor.visit(tasks)
    [tasks, task_string_extractor.collector]
  end
end
