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

  def concat(models)
    owner.set_member_subject_ids_will_change!
    owner.set_member_subject_ids.concat(models.map(&:id))
    owner.save!
  end

  def destroy(*models)
    owner.set_member_subject_ids_will_change!
    owner.set_member_subject_ids.delete(*models.map(&:id))
    owner.save!
  end
  
  def add_subject(model)
    concat([model])
  end

  def remove_subject(model)
    destroy(model)
  end
end

