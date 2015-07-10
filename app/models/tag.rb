class Tag < ActiveRecord::Base
  include PgSearch
  has_many :tagged_resources
  has_many :resources

  validates_presence_of :name

  pg_search_scope :search_tags,
    against: :name,
    using: :trigram,
    ranked_by: ":trigram"

  def self.scope_for(*args)
    all
  end
end
