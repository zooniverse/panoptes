class Api::V1::WorkflowsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  resource_actions :default

  alias_method :workflow, :controlled_resource
  
  def show
    load_cellect
    super
  end

  private

  def load_cellect
    return unless api_user.logged_in?
    Cellect::Client.connection.load_user(**cellect_params)
  end

  def build_resource_for_update(update_params)
    if update_params.has_key? :tasks
      stripped_tasks, strings = extract_strings(update_params[:tasks])
      update_params[:tasks] = stripped_tasks
      workflow.primary_content.update!(strings: strings)
    end
    super(update_params)
  end

  def build_resource_for_create(create_params)
    stripped_tasks, strings = extract_strings(create_params[:tasks])
    create_params[:tasks] = stripped_tasks
    workflow = super(create_params)
    WorkflowContent.create!(workflow: workflow,
                            strings: strings,
                            language: workflow.primary_language)
    workflow
  end

  def extract_strings(tasks)
    collector = []
    TasksVisitors::ExtractStrings.new.visit(tasks, collector)
    [tasks, collector]
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
    params[:workflows].fetch(:tasks, [])
      .reduce([]) do |permitted, (task_name, _)|
      permitted.concat([task_name => [:type,
                                      :question,
                                      :next,
                                      tools: [:value, :label, :type, :color],
                                      answers: [:value, :label]]])
    end
  end
end
