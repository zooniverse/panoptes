class TalkAdminCreateWorker
  include Sidekiq::Worker

  def perform(project_id)
    Project.find(project_id).create_talk_admin(client)
  end

  def client
    @client ||= TalkApiClient.new
  end
end
