class PublishClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :classification

  def perform(classification_id)
    @classification = Classification.find(classification_id)
    if classification.complete?
      publish_to_kinesis!
    end
  rescue ActiveRecord::RecordNotFound
  end

  private

  def serialized_classification
    @serialized_classification ||= EventStreamSerializers::ClassificationSerializer
      .serialize(classification, include: ['project', 'workflow', 'workflow_content', 'user', 'subjects'])
      .as_json
      .with_indifferent_access
  end

  def publish_to_kinesis!
    ZooStream.publish(event: "classification",
                      data: kinesis_data,
                      linked: kinesis_linked,
                      shard_by: classification.workflow_id)
  end

  def kinesis_data
    serialized_classification[:classifications][0]
  end

  def kinesis_linked
    serialized_classification[:linked]
  end
end
