module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    render json_api: RecentsSerializer.page(ps, recent_scope, { type: resource_sym.to_s })
  end

  def recent_scope
    Recent.joins(:classification)
      .eager_load(:subject, :locations)
      .where(classifications: { :"#{resource_name}_id" => resource_ids})
  end
end
