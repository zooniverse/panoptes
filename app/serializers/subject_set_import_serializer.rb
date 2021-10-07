class SubjectSetImportSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer
  using Refinements::RangeClamping

  attributes :id, :href, :created_at, :updated_at, :source_url, :imported_count, :manifest_count, :progress
  can_include :subject_set, :user

  can_filter_by :subject_set, :user

  def progress
    binding.pry
    # calculate and clamp the progress value between 0.0 and 1.0, i.e. 0 to 100%
    progress = (imported_count * 1.0) / (manifest_count * 1.0)
    (0.0..1.0).clamp(progress)
  end
end
