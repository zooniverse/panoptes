class Api::V1::WorkflowsController < Api::ApiController
  include Versioned
  include TranslatableResource

  doorkeeper_for :update, :create, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  attr_accessor :workflow_project_id

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
    @workflow_project_id = resource.project_id
    items = construct_new_items(super(resource, relation, value))
    if items.any? { |item| item.is_a?(SubjectSet) }
      items
    else
      items.first
    end
  end

  def construct_new_items(item_scope)
    Array.wrap(item_scope).map do |item|
      if item.is_a?(SubjectSet) && !item.belongs_to_project?(workflow_project_id)
        duplicate_subject_set_and_subjects(item)
      else
        item
      end
    end
  end

  def duplicate_subject_set_and_subjects(orig_subject_set)
    orig_subject_set.dup.tap do |subject_set|
      subject_set.project_id = workflow_project_id
      subject_set.set_member_subjects_count = 0
      subject_set.set_member_subjects = [].tap do |new_smss|
        orig_subject_set.set_member_subjects.find_each do |sms|
          new_smss << SetMemberSubject.new(subject_set: subject_set, subject_id: sms.subject_id)
        end
      end
    end
  end
end
