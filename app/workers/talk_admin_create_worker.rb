class TalkAdminCreateWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id)
    Project.find(project_id).create_talk_admin(client)
  rescue TalkApiClient::NoTalkHostError => e
    Rails.logger.info e # TODO: remove when production talk is deployed
  end

  def client
    @client ||= TalkApiClient.new
  end
end
