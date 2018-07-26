class AddConfidentialToDoorkeeperApplication < ActiveRecord::Migration
  def change
    add_column(
      :oauth_applications,
      :confidential,
      :boolean,
      null: false,
      default: true # maintaining backwards compatibility: require secrets
      # setting all the existing apps to confidential will break login for grants (password)
      # that do not supply a client_secret, e.g. our main zooniverse.org UI and api clients
      # these apps will require a confidential = false setting
      # all implicit apps will require confidential = false as well
      # apps that can keep secrets and use them to authenticate will require the default value
    )
  end
end
