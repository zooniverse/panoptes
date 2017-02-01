module RoleControl
  module Editors
    extend ActiveSupport::Concern

    included do
      has_many :access_control_lists, as: :resource, dependent: :destroy
      has_one :editor_list, -> { where.overlap(roles: ["owner", "collaborator"]) }, as: :resource, class_name: "AccessControlList"
      has_many :editors, through: :editor_list, source: :user_group, as: :resource, class_name: "UserGroup"

      scope :public_scope, -> { where(private: false) }

      def self.filter_by_editor(editor_groups)
        eager_load(editors: { identity_membership: :user })
        .joins(:editors)
        .where(access_control_lists: { user_group: editor_groups })
      end
    end
  end
end
