class ClassificationsExportSegment < ActiveRecord::Base
  belongs_to :project
  belongs_to :workflow
  belongs_to :first_classification, class_name: 'Classification', foreign_key: 'first_classification_id'
  belongs_to :last_classification,  class_name: 'Classification', foreign_key: 'last_classification_id'
  belongs_to :requester, class_name: 'User', foreign_key: 'requester_id'

  has_one :medium, as: :linked

  def classifications_in_segment
    complete_classifications
      .where("classifications.id >= ? AND classifications.id <= ?", first_classification_id, last_classification_id)
      .joins(:workflow)
      .includes(:user, workflow: [:workflow_contents])
  end

  def next_segment
    res = complete_classifications
            .where("id > ?", last_classification_id)
            .select("min(id), max(id)")
            .limit(1)
            .load[0]

    next_first_id = res.min
    next_last_id  = res.max

    self.class.new(
      project_id: project_id,
      workflow_id: workflow_id,
      requester: requester,
      first_classification_id: next_first_id,
      last_classification_id: next_last_id
    )
  end

  private

  def complete_classifications
    workflow.classifications.complete
  end
end
