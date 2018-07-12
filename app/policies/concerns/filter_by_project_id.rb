module FilterByProjectId
  def self.remove_non_exportable_projects(scope)
    # Tested on prod all projects table scan:
    # "Seq Scan on public.projects  (cost=0.00..1097.20 rows=6 width=4) (actual time=16.918..16.918 rows=0 loops=1)"
    # "  Output: id"
    # "  Filter: (projects.configuration ? 'keep_data_in_panoptes_only'::text)"
    # "  Rows Removed by Filter: 5776"
    # "Planning time: 0.101 ms"
    # "Execution time: 23.301 ms

    # this seems to add a small overhead to the query, it should be
    # removed once the panoptes only data project has finished
    forbidden_project_ids = Project.where("configuration ? 'keep_data_in_panoptes_only'").select(:id)
    exportable_scope = scope.where.not(project_id: forbidden_project_ids)
  end
end
