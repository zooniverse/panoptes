require 'spec_helper'

describe TranslationStrings do
  def project_strings(resource)
    {
      "display_name" => resource.display_name,
      "title" => "A Test Project",
      "description" => "Some Lorem Ipsum",
      "workflow_description" => "Go outside",
      "introduction" => "MORE IPSUM",
      "researcher_quote" => "This is my favorite project",
      "url_labels" => {
        "0.label"=>"Blog",
        "1.label"=>"Twitter",
        "2.label"=>"Science Case"
      }
    }
  end

  def workflow_strings(resource)
    {
      "display_name" => "A Workflow",
      "tasks" => {
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

  def tutorial_strings(resource)
    {
      "display_name" => "A Tutorial",
      "steps" =>
      [
        {
          "media" => "asdfasdf",
          "content" => "asdfkajlsdf;"
        },
        {
          "media" => "asdfasdf",
          "content" => "asdkfljds;lj"
        }
      ]
    }
  end

  def field_guide_strings(resource)
    {
      "items" =>
      [
        {
          "title" => "Page 1",
          "content" => "stuff and things"
        },
        {
          "title" => "Other guide",
          "content" => "animals & such"
        }
      ]
     }
  end

  def project_page_strings(resource)
    {
      "title" => "Science Case",
      "content" => "Crap about science"
    }
  end

  def organization_strings(resource)
    {
      "display_name" => resource.display_name,
      "title" => "Test Organization",
      "description" => "This is the description for an Organization",
      "introduction" => "This is the intro for an Organization",
      "url_labels" => {
        "0.label" => "Blog",
        "1.label" => "Twitter"
      }
    }
  end

  def organization_page_strings(resource)
    {
      "title" => "Science Case",
      "content" => "Crap about science"
    }
  end

  %i(project workflow field_guide organization_page organization project_page tutorial).each do |resource_type|
    describe "#extract" do
      it "should extract all the available content to a strings hash" do
        resource = create(resource_type)
        subject = TranslationStrings.new(resource)
        expect(subject.extract).to eq(send("#{resource_type}_strings", resource))
      end
    end
  end
end
