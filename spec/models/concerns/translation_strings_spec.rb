require 'spec_helper'

describe TranslationStrings do
  def project_strings
    {
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
    {}
  end

  def tutorial_strings
    {}
  end

  def field_guide_strings
    {}
  end

  def project_page_strings
    {}
  end

  def organization_page_strings
    {}
  end

  %i(project workflow tutorial field_guide project_page organization_page).each do |resource_type|

    describe "#extract" do
      it "should extract all the available content to a strings hash", :focus do
        resource = create(resource_type)
        subject = TranslationStrings.new(resource)
        expect(subject.extract).to eq(send("#{resource_type}_strings"))
      end
    end
  end
end
