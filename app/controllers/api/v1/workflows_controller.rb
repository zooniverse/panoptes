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
                  :tasks, permit_tasks,
                  :first_task,
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
