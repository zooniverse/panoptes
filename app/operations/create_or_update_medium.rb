class CreateOrUpdateMedium < Operation
  object :object
  symbol :type

  hash :media do
    string :content_type, default: 'text/csv'
    hash :metadata, default: {} do
      array :recipients, default: -> { [api_user.id] } do
        integer
      end
    end
    # default to private exports by default, can be overiden
    # by operation input composition `inputs.merge(media: { private: true })`
    boolean :private, default: -> { true }
  end

  def execute
    media['metadata']["state"] = 'creating'
    medium = find_existing_medium

    if medium
      medium.update!(media)
      medium.touch
      cleanup_duplicate_media(medium)
      medium
    else
      new_medium = object.send("create_#{type}!", media)
      cleanup_duplicate_media(new_medium)
      new_medium
    end
  end

  private

  def find_existing_medium
    scoped_media
      .order(updated_at: :desc, id: :desc)
      .first
  end

  def cleanup_duplicate_media(primary_medium)
    return unless primary_medium

    scoped_media
      .where.not(id: primary_medium.id)
      .find_each(&:destroy)
  end

  def scoped_media
    @scoped_media ||= object.association(type).scope.unscope(:order, :limit)
  end
end
