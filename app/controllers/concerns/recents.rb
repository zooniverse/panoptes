module Recents
  def recents
    ps = params.dup
    ps.delete "#{resource_name}_id"
    render json_api: RecentsSerializer.page(ps, recent_scope, { type: resource_sym.to_s })
  end

  def recent_scope
    Classification.joins(resource_name.to_sym)
      .merge(controlled_resources)
      .where(completed: true)
      .joins('INNER JOIN "subjects" ON "subjects"."id" = ANY("classifications"."subject_ids")')
      .select('"classifications"."id", "classifications"."project_id", "classifications"."workflow_id", "classifications"."updated_at", "classifications"."created_at", "subjects"."locations", "subjects"."id" as subject_id')
  end
end
