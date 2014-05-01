class ZooniverseUser < ActiveRecord::Base
  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'users'

  
end
