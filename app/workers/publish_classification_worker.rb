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
      .serialize(classification, include: ['project', 'workflow', 'user', 'subjects'])
      .as_json
      .with_indifferent_access
  end

  def publish_to_kinesis!
    ZooStream.publish(
      event: "classification",
      data: kinesis_data,
      linked: kinesis_linked,
      shard_by: [classification.workflow_id, classification.subject_ids].flatten.join("-")
    )
  rescue Aws::Kinesis::Errors::ValidationException => e
    handle_kinesis_error(e)
  end

  def kinesis_data
    serialized_classification[:classifications][0]
  end

  def kinesis_linked
    serialized_classification[:linked]
  end

  def ignore_project_ids_list
    ENV.fetch('KINESIS_PAYLOAD_SIZE_ERROR_PROJECT_ID_INGORE_LIST', '').split(',')
  end

  def handle_kinesis_error(error)
    # Aws::Kinesis::Errors::ValidationException are broad and contain the specific error data in message
    # therefore only test for these data payload size errors
    # all others we raise on to keep visibility to kinesis publishing errors
    raise error unless error.message.include?("Value at 'data' failed to satisfy constraint: Member must have length less than or equal to")

    # re-raise if this classification's project isn't in the ignore list
    raise error unless ignore_project_ids_list.include?(classification.project_id.to_s)
  end
end
