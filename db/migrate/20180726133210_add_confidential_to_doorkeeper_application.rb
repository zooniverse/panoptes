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

        # only change the apps we know use the password grant without a client_secret
        known_non_confidential_first_party_app_names = [
          "ZooniverseFirstParty - PFE",
          "Panoptes python client - official",
          "PFE Application"
        ]
        Doorkeeper::Application
        .first_party # all first_party apps (e.g. PFE, python client)
        .where(name: known_non_confidential_first_party_app_names)
        .where.not(confidential: false)
        .update_all(non_confidential_opts)
      end
    end
  end
end
