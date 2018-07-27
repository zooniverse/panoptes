class AddConfidentialToDoorkeeperApplication < ActiveRecord::Migration
  def change
    add_column(
      :oauth_applications,
      :confidential,
      :boolean,
      null: false,
      default: true # maintaining backwards compatibility: require secrets
    )

    # setting all the existing apps to confidential will break login for grant flows(password)
    # that do not supply a client_secret, e.g. our main zooniverse.org UI and api clients
    # these apps will require a confidential = false setting
    # all implicit apps will require confidential = false as well
    # apps that can keep secrets and use them to authenticate will require the default value
    reversible do |dir|
      dir.up do
        non_confidential_opts = { confidential: false }

        Doorkeeper::Application
        .where("redirect_uri ~* ?", '://') # all implicit apps & native apps (protocol scheme in the redirect_uri)
        .where("redirect_uri !~* ?", 'auth/.+/callback') # not the omniauth server apps
        .update_all(non_confidential_opts)

        #2. set the first party apps that aren't already set (PFE / python client)
        Doorkeeper::Application
        .first_party
        .where("redirect_uri !~* ?", 'auth/.+/callback') # not the omniauth server apps
        .where.not(confidential: false)
        .update_all(non_confidential_opts)
      end
    end
  end
end
