require 'spec_helper'

describe TranslationStrings do
  def project_strings
    {
      "display_name" => "A Test Project",
      "title" => "A Test Project",
      "description" => "Some Lorem Ipsum",
      "workflow_description" => "Go outside",
      "introduction" => "MORE IPSUM",
      "researcher_quote" => "This is my favorite project",
      "url_labels" =>{
        "0.label"=>"Blog",
        "1.label"=>"Twitter",
        "2.label"=>"Science Case"
      }
    }
  end

  def workflow_strings
    {
      "display_name" => "A Workflow",
      "strings" => {
        "interest.question" => "Draw a circle",
        "interest.help" => "Duh?",
        "interest.tools.0.label" => "Red",
        "interest.tools.1.label" => "Green",
        "interest.tools.2.label" => "Blue",
        "shape.question" => "What shape is this galaxy",
        "shape.help" => "Duh?",
        "shape.answers.0.label" => "Smooth",
        "shape.answers.1.label" => "Features",
        "shape.answers.2.label" => "Star or artifact"
      }
    }
  end

  def tutorial_strings
    {}
  end

  def field_guide_strings
    {
      "items" =>
      [
        {
          "title" => "Page 1",
          "content" => "stuff and things",
          "icon" => "123456"
        }, {
          "title" => "Other guide",
          "content" => "animals & such",
          "icon" => "654321"
        }
      ]
     }
  end

  def project_page_strings
    {}
  end

  def organization_strings
    {}
  end

  def organization_page_strings
    {}
  end

  %i(project workflow tutorial field_guide project_page organization organization_page).each do |resource_type|

    describe "#extract" do
      it "should extract all the available content to a strings hash", :focus do
        resource = create(resource_type)
        subject = TranslationStrings.new(resource)
        expect(subject.extract).to eq(send("#{resource_type}_strings"))
      end
    end
  end
end
