class Tag < ActiveRecord::Base
  include PgSearch::Model
  has_many :tagged_resources
  has_many :projects, through: :tagged_resources, source: :resource, source_type: "Project"
  has_many :organizations, through: :tagged_resources, source: :resource, source_type: "Organization"

  validates :name, uniqueness: { case_sensitive: false }, presence: true

  before_validation :downcase_name

  pg_search_scope :search_tags,
    against: :name,
    using: :trigram,
    ranked_by: ":trigram"

  def downcase_name
    self.name = name.try(:downcase)
  end
end
