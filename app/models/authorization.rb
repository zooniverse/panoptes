# frozen_string_literal: true

class Authorization < ApplicationRecord
  belongs_to :user

  validates_presence_of :provider, :uid, :token
  validates_uniqueness_of :provider, scope: :user_id
end
