require 'spec_helper'

describe Subjects::DesignatorSelector do
  let(:client) { instance_double(DesignatorClient) }
  let(:workflow) { instance_double(Workflow, id: 1) }
  let(:selector) { described_class.new(workflow)}

  before do
    allow(described_class).to receive(:client).and_return(client)
  end

  describe '#add_seen' do
    it 'adds seens using the client' do
      expect(client).to receive(:add_seen).with(1, 2, 3)
      selector.add_seen(2, 3)
    end

    it 'does nothing unless enabled' do
      Flipper.disable(:designator)
      expect(client).not_to receive(:add_seen)
      selector.add_seen(2, 3)
    end
  end

  describe '#load_user' do
    it 'loads users using the client' do
      expect(client).to receive(:load_user).with(1, 2)
      selector.load_user(2)
    end

    it 'does nothing unless enabled' do
      Flipper.disable(:designator)
      expect(client).not_to receive(:load_user)
      selector.load_user(2)
    end
  end

  describe '#reload_workflow' do
    it 'reloads workflows using the client' do
      expect(client).to receive(:reload_workflow).with(1)
      selector.reload_workflow
    end

    it 'does nothing unless enabled' do
      Flipper.disable(:designator)
      expect(client).not_to receive(:reload_workflow)
      selector.reload_workflow
    end
  end

  describe '#remove_subject' do
    it 'removes subjects using the client' do
      expect(client).to receive(:remove_subject).with(3, 1)
      selector.remove_subject(3)
    end

    it 'does nothing unless enabled' do
      Flipper.disable(:designator)
      expect(client).not_to receive(:remove_subject)
      selector.remove_subject(3)
    end
  end

  describe '#get_subjects' do
    let(:user) { instance_double(User, id: 2) }
    let(:workflow) { create(:workflow) }

    it 'gets subjects using the client' do
      expect(client).to receive(:get_subjects).with(workflow.id, 2, nil, 10).and_return([])
      selector.get_subjects(user, nil, 10)
    end

    it 'returns an empty array unless enabled', :aggregate_failures do
      Flipper.disable(:designator)
      expect(client).not_to receive(:get_subjects)

      subject_ids = selector.get_subjects(user, nil, 10)
      expect(subject_ids).to eq([])
    end
  end
end
