class AddTrigramIndexesToDisplayNameColumns < ActiveRecord::Migration
  def change
    %i(projects collections user_groups).each do |table|
      add_index table, :display_name, operator_class: :gist_trgm_ops, using: :gist,
        name: "#{table}_display_name_trgm_index"
    end
  end
end
