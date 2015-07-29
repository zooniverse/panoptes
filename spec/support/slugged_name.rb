RSpec.shared_examples "has slugged name" do
  describe '#slugged_name' do
    let(:resource){ create described_class.name.underscore, display_name: 'Some Awesome Project / Other Stuff', owner: owner }
    subject{ resource.slug }
    context "when owner is a user" do
      let(:owner){ create :user, login: 'somebody' }
      it{ is_expected.to eql 'somebody/some-awesome-project-other-stuff' }
    end

    context "when owner is a user group" do
      let(:owner){ create :user_group, name: 'somebody' }
      it{ is_expected.to eql 'somebody/some-awesome-project-other-stuff' }
    end
  end
end
