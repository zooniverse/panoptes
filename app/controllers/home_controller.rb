class HomeController < Api::ApiController

  def index
    respond_to do |format|
      format.json { render json: {} }
      format.json_api { render json_api: {} }
      format.html { render }
    end
  end
end
