## This is a pretty gross hack until I figure out how make normal
## ActiveRecord Associations work with a field that's an array of
## foreign keys. It should be possible but that part of AR is pretty
## hairy and I'd like to finish a basic version of this feature as
## quickly as possible

## This doesn't replicate all of AR:A just enough to fool RestPack and
## JsonApiController into thinking its one. 

class SetMemberSubjectRelation
  include Enumerable
  
  attr_reader :owner

  delegate :each, to: :@relation
  
  def initialize(owner)
    @owner = owner
    @relation = SetMemberSubject.where(id: owner.set_member_subject_ids)
  end

  def concat(*models)
    models = models.flatten
    owner.set_member_subject_ids_will_change!
    ids = models.map { |m| m.try(:id) || m }
    owner.set_member_subject_ids.concat(ids)
    owner.save!
  end

  def destroy(*models)
    models = models.flatten
    owner.set_member_subject_ids_will_change!
    ids = models.map { |m| m.try(:id) || m }
    owner.set_member_subject_ids.delete(*ids)
    owner.save!
  end
  
  def add_subjects(models)
    concat([models])
  end

  def remove_subjects(models)
    destroy(models)
  end
end

