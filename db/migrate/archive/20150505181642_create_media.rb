class CreateMedia < ActiveRecord::Migration
  def change
    create_table :media do |t|
      t.string :type, index: true
      t.references :linked, polymorphic: true, index: true
      t.string :content_type
      t.text :src
      t.text :path_opts, array: true, default: []
      t.boolean :private, default: false
      t.boolean :external_link, default: false
      t.timestamps null: false
    end

    total = Subject.count
    Subject.find_each.with_index do |subject, i|
      p "#{i+1} of #{total}"
      subject.attributes["locations"].each do |loc|
        content = loc.keys.first
        src = loc.values.first
        Medium.create!(linked: subject,
                       src: src,
                       content_type: content,
                       type: "subject_location")
      end
    end

    remove_column :subjects, :locations
  end
end
