class CreateClassificationsExportSegments < ActiveRecord::Migration
  def up
    create_table :classifications_export_segments do |t|
      t.references :project, null: false, index: true, foreign_key: true
      t.references :workflow, null: false, index: true, foreign_key: true
      t.integer :first_classification_id, null: false
      t.integer :last_classification_id, null: false
      t.integer :requester_id, null: false

      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps null: false
    end

    ClassificationsExportSegment.connection.execute <<-SQL
ALTER TABLE ONLY classifications_export_segments
    ADD CONSTRAINT fk_rails_75356fc305 FOREIGN KEY (first_classification_id) REFERENCES classifications(id) NOT VALID;
ALTER TABLE ONLY classifications_export_segments
    ADD CONSTRAINT fk_rails_d88309a3be FOREIGN KEY (last_classification_id) REFERENCES classifications(id) NOT VALID;
ALTER TABLE ONLY classifications_export_segments
    ADD CONSTRAINT fk_rails_2cc7401a1f FOREIGN KEY (requester_id) REFERENCES users(id) NOT VALID;
SQL
  end

  def down

    ClassificationsExportSegment.connection.execute <<-SQL
ALTER TABLE ONLY classifications_export_segments DROP CONSTRAINT fk_rails_75356fc305;
ALTER TABLE ONLY classifications_export_segments DROP CONSTRAINT fk_rails_d88309a3be;
ALTER TABLE ONLY classifications_export_segments DROP CONSTRAINT fk_rails_2cc7401a1f;
SQL
    drop_table :classifications_export_segments
  end
end
