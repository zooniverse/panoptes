# This class contains the historical gold standard classification annotations.
# They have been ported to this table as a read only resource, as they are
# used to provide accuracy feedback for users in specific Zooniverse
# projects. This feedback mechanism changed from GS annotations to
# standardized subject metadata instead so teams can selfservice via uploads.
#
# Thus this is a snapshot of the GS data to support only specific Zoo projects
# (see the project / workflow ids for the data in this table)
#
# Long term this can probably go, but please check that the projects have
# been retired and don't need this data for the feedback mechanism.
class GoldStandardAnnotation < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :subject
  belongs_to :project
  belongs_to :user
  belongs_to :classification

  validates_presence_of :workflow,
    :subject,
    :project,
    :user,
    :classification,
    :metadata,
    :annotations
end
