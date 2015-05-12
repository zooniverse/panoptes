class CreateRecents < ActiveRecord::Migration
  def change
    create_table :recents do |t|
      t.references :classification, index: true, foreign_key: true
      t.references :subject, index: true, foreign_key: true

      t.timestamps null: false
    end

    total = Classification.count
    Classification.find_each.with_index do |c,i|
      p "#{i+1} of #{total}"
      c.subject_ids.each do |s|
        Recent.create!(classification: c, subject_id: s)
      end
    end
  end
end
