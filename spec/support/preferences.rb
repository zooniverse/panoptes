RSpec.shared_examples "has preferences scope" do
  let!(:user) { create(:user) }
  let(:preferences_model) { described_class.to_s.underscore }
  let(:preferences_for) { described_class.instance_variable_get(:@preferences_for) }
  let!(:preferences) do
    prefs_for_actor = create(preferences_model, user: user)
    public_prefs = create(preferences_model, public: true)
    private_prefs = create(preferences_model)
    private_parent = create(preferences_model, public: true,
      preferences_for => create(preferences_for, private: true))
    [prefs_for_actor, public_prefs, private_prefs, private_parent]
  end
  let(:action) { actions.sample }

  subject{ described_class.scope_for(action, user) }

  context "when action is index or show" do
    let(:actions) { ["index", "show"] }

    it 'should return preferences for the acting user' do
      expect(subject).to include(preferences[0])
    end

    it 'should return public preferences' do
      expect(subject).to include(preferences[1])
    end

    it 'should not include private preference' do
      expect(subject).to_not include(preferences[2])
    end

    it 'should not include preference belonging to a private model' do
      expect(subject).to_not include(preferences[3])
    end
  end

  context "when action is update or destroy" do
    let(:actions) { ["update", "destroy"] }

    it 'should only return the prefs for the acting user' do
      expect(subject).to match_array(preferences.slice(0,1))
    end
  end
end
