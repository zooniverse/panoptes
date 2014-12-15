class Api::V1::WorkflowsController < Api::ApiController
  include JsonApiController
  include Versioned

  doorkeeper_for :update, :create, :destroy, scopes: [:project]
  resource_actions :create, :update, :destroy
  schema_type :json_schema

  allowed_params :create
  allowed_params :update

  alias_method :workflow, :controlled_resource

  def show
    load_cellect
    render json_api: serializer.resource(params,
                                         visible_scope,
                                         languages: current_languages)
  end

  def index
    render json_api: serializer.page(params,
                                     visible_scope,
                                     languages: current_languages)
  end

  private

  def create_response(workflow)
    serializer.resource({},
                        resource_scope(workflow),
                        languages: [workflow.primary_language])
  end

  def update_response(workflow)
    create_response(workflow)
  end

  def load_cellect
    return unless api_user.logged_in?
    Cellect::Client.connection.load_user(**cellect_params)
  end

  def build_resource_for_update(update_params)
    if update_params.has_key? :tasks
      stripped_tasks, strings = extract_strings(update_params[:tasks])
      update_params[:tasks] = stripped_tasks
      workflow.primary_content.update_attributes(strings: strings)
    end
    super(update_params)
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

  def cellect_params
    {
      host: cellect_host(params[:id]),
      user_id: api_user.id,
      workflow_id: params[:id]
    }
  end
end
