class KafkaEventSerializer
  attr_reader :attributes, :links
  
  def initialize(attributes=[], links=[])
    @attributes, @links = attributes, links
  end

  def serialize(model)
    hash = Hash.new
    hash = { id: SecureRandom.uuid }
    hash = hash.merge(serialize_attributes(model))
    hash[:links] = serialize_links(model)
    hash[:links][model.class.model_name.singular.to_sym] = model.id.to_s
    hash
  end

  private

  def serialize_attributes(model)
    attributes.map do |attr|
      { attr => model.send(attr) }
    end.reduce(&:merge)
  end
  
  def serialize_links(model)
    links.map do |link|
      reflection = model.class.reflect_on_association(link)
      case reflection.macro
      when :has_many, :has_and_belongs_to_many
        if model.send(link).loaded?
          { link => model.send(link).map(&:id).map(&:to_s) }
        else
          { link => model.send(link).pluck(:id).map(&:to_s) }
        end
      when :has_one, :belongs_to
        if reflection.polymorphic?
          linked = model.send(link)
          {link => {id: linked.id.to_s,
                    type: linked.class.model_name.singular}}
        else
          { link => model.send(link).id.to_s }
        end
      end
    end.reduce(&:merge)
  end
end
