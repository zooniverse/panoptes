require 'spec_helper'

describe TranslationStrings do
  def project_strings(resource)
    {
      "display_name" => resource.display_name,
      "title" => resource.display_name,
      "description" => "Some Lorem Ipsum",
      "workflow_description" => "Go outside",
      "introduction" => "MORE IPSUM",
      "researcher_quote" => "This is my favorite project",
      "url_labels.0.label"=>"Blog",
      "url_labels.1.label"=>"Twitter",
      "url_labels.2.label"=>"Science Case"
    }
  end

  def workflow_strings(resource)
    {
      "display_name" => "A Workflow",
      "tasks.interest.question" => "Draw a circle",
      "tasks.interest.help" => "Duh?",
      "tasks.interest.tools.0.label" => "Red",
      "tasks.interest.tools.1.label" => "Green",
      "tasks.interest.tools.2.label" => "Blue",
      "tasks.interest.tools.3.label" => "Purple",
      "tasks.interest.tools.3.details.0.answers.0.label" => "Painfully wow",
      "tasks.interest.tools.3.details.0.answers.1.label" => "Just wow",
      "tasks.interest.tools.3.details.0.question" => "Wow rating:",
      "tasks.shape.question" => "What shape is this galaxy",
      "tasks.shape.help" => "Duh?",
      "tasks.shape.answers.0.label" => "Smooth",
      "tasks.shape.answers.1.label" => "Features",
      "tasks.shape.answers.2.label" => "Star or artifact"
    }
  end

  def tutorial_strings(resource)
    {
      "display_name" => "A Tutorial",
      "steps.0.content" => "asdfkajlsdf;",
      "steps.1.content" => "asdkfljds;lj"
    }
  end

  def field_guide_strings(resource)
    {
      "items.0.title" => "Page 1",
      "items.0.content" => "stuff and things",
      "items.1.title" => "Other guide",
      "items.1.content" => "animals & such"
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
      "title" => resource.display_name,
      "description" => "This is the description for an Organization",
      "introduction" => "This is the intro for an Organization",
      "announcement" => "Alert: This organization has something to let you know",
      "url_labels.0.label" => "Blog",
      "url_labels.1.label" => "Twitter"
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
