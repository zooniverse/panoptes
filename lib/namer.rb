class Namer
  def self.set_name_fields(params)
    params[:display_name] ||= params[:name]
    params[:name] ||= CGI.escape(params[:display_name].downcase.gsub(/\s+/, "_"))
  end
end
