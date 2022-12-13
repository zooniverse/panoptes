class CreateProjectPages < ActiveRecord::Migration
  def change
    create_table :project_pages do |t|
      t.string :url_key
      t.text :title
      t.string :language
      t.text :content
      t.references :project, index: true

      t.timestamps null: false
    end

    add_index :project_pages, :language

    pages = [["science_case", "Research Case"], ["faq", "FAQ"], ["result", "Result"], ["education", "Education", "education_content"]]

    ProjectContent.find_each do |content|
      pages.each do |(url, title, field)|
        field = url unless field
        ProjectPage.create!(title: title, url_key: url, content: content.send(field), language: content.language, project_id: content.project_id)
      end
    end

    %i(science_case faq result education_content guide team_members).each do |column|
      remove_column :project_contents, column
    end
  end
end
