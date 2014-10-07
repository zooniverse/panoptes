class HomeController < Api::ApiController

  def index
    respond_to do |format|
      format.html { render }
      format.json { render json: {} }
      format.json_api { render json_api: {} }
    end
  end
end
