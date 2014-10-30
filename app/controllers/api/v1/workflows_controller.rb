class Api::V1::WorkflowsController < Api::ApiController
  include JsonApiController
  include Versioned

  doorkeeper_for :update, :create, :delete, scopes: [:project]
  resource_actions :create, :update, :destroy

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
    serializer.resource(workflow,
                        nil,
                        languages: [workflow.primary_language])
  end

  def update_response
    render json_api: create_response(workflow)
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

  def create_params
    permit_params(:pairwise,
                  :grouped,
                  :prioritized,
                  :name,
                  :primary_language,
                  :first_task,
                  tasks: permit_tasks,
                  links: [:project,
                          subject_sets: []])
  end

  def update_params

    permit_params(:pairwise,
                  :grouped,
                  :prioritized,
                  :name,
                  :first_task,
                  tasks: permit_tasks,
                  links: [subject_sets: []])
  end

  def permit_params(*permitted)
    params.require(:workflows).permit(*permitted)
  end

  def permit_tasks
    tasks = params[:workflows].fetch(:tasks, [])

    tasks.reduce([]) do |permitted, (task_name, _)|
      permitted.concat([task_name => [:type,
                                      :question,
                                      :next,
                                      tools: [:value, :label, :type, :color],
                                      answers: [:value, :label]]])
    end
  end
end
