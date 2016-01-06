require 'spec_helper'

RSpec.describe FastProjectSerializer, type: :serializer do
  let(:params){ { } }
  let(:serializer){ FastProjectSerializer.new params }

  describe '#initialize' do
    let(:params){ { foo: 'bar' } }
    subject{ serializer.params }
    it{ is_expected.to eql params }
  end

  describe '#page' do
    subject{ serializer.page }

    context 'with a param' do
      let(:params){ { page: '123' } }
      it{ is_expected.to eql 123 }
    end

    context 'without a param' do
      it{ is_expected.to eql 1 }
    end
  end

  describe '#page_size' do
    subject{ serializer.page_size }

    context 'with a param' do
      let(:params){ { page_size: '123' } }
      it{ is_expected.to eql 123 }
    end

    context 'without a param' do
      it{ is_expected.to eql 20 }
    end
  end

  describe '#query' do
    let(:query_double){ double }
    let(:order_double){ double }

    before(:each) do
      allow(Project).to receive(:where).and_return query_double
      allow(query_double).to receive(:order).and_return order_double
      allow(order_double).to receive(:eager_load)
    end

    it 'should filter to launched projects' do
      expect(Project).to receive(:where).with(launch_approved: true).and_return query_double
      serializer.query
    end

    it 'should order by launch' do
      expect(query_double).to receive(:order).with :launched_row_order
      serializer.query
    end

    it 'should eager load associations' do
      expect(order_double).to receive(:eager_load).with :avatar, :project_contents
      serializer.query
    end

    it 'should memoize the result' do
      expect(serializer.query.object_id).to eql serializer.query.object_id
    end
  end

  describe '#paginated' do
    let(:query_double){ double }
    let(:page_double){ double }
    let(:params){ { page: 123, page_size: 1 } }

    before(:each) do
      allow(serializer).to receive(:query).and_return query_double
      allow(query_double).to receive(:page).and_return page_double
      allow(page_double).to receive :per
    end

    it 'should use the query' do
      expect(serializer).to receive :query
      serializer.paginated
    end

    it 'should paginate the query' do
      expect(query_double).to receive(:page).with 123
      serializer.paginated
    end

    it 'should set the page size' do
      expect(page_double).to receive(:per).with 1
      serializer.paginated
    end

    it 'should memoize the result' do
      expect(serializer.paginated.object_id).to eql serializer.paginated.object_id
    end
  end

  describe '#meta' do
    let!(:projects){ create_list :project, 3, launch_approved: true }
    let(:params){ { page: 2, page_size: 1 } }
    subject{ serializer.meta['projects'] }

    # Condensed to one example for performance
    it 'should format metadata' do
      expect(subject).to include 'page' => 2
      expect(subject).to include 'page_size' => 1
      expect(subject).to include 'count' => 3
      expect(subject).to include 'include' => ['avatar']
      expect(subject).to include 'page_count' => 3
      expect(subject).to include 'previous_page' => 1
      expect(subject).to include 'next_page' => 3
      expect(subject).to include 'first_href' => '/projects?simple=true'
      expect(subject.keys).to include 'previous_href', 'next_href', 'last_href'
    end
  end

  describe '#page_href' do
    let(:page){ }
    let(:params){ { page_size: 2 } }
    subject{ serializer.page_href page }

    context 'when the page does not exist' do
      it{ is_expected.to be_nil }
    end

    context 'when the page does exist' do
      let(:page){ 123 }
      it{ is_expected.to eql '/projects?simple=true&page=123&page_size=2' }
    end
  end

  describe '#project_data' do
    let(:project){ create :project }
    subject{ serializer.project_data project }
    it{ is_expected.to include 'id' => project.id.to_s }
    it{ is_expected.to include 'display_name' => project.display_name }
    it{ is_expected.to include 'description' => project.project_contents.first.description }
    it{ is_expected.to include 'title' => project.project_contents.first.title }
    it{ is_expected.to include 'slug' => project.slug }
    it{ is_expected.to include 'redirect' => project.redirect }
    it{ is_expected.to include 'available_languages' => ['en'] }
    it{ is_expected.to have_key 'avatar_src' }
  end

  describe '#avatar_src' do
    let(:avatar){ }
    subject{ serializer.avatar_src avatar }

    context 'when the avatar does not exist' do
      it{ is_expected.to be_nil }
    end

    context 'when the avatar is an internal link' do
      let(:avatar){ double external_link: false, src: 'internal.jpg' }
      it{ is_expected.to eql '//internal.jpg' }
    end

    context 'when the avatar is an external link' do
      let(:avatar){ double external_link: true, src: 'external.jpg' }
      it{ is_expected.to eql 'external.jpg' }
    end
  end

  RSpec.shared_context 'fast_serializer_project_contents' do
    let!(:project){ create :project, primary_language: 'ab-cd' }
    let!(:primary_content){ create :project_content, project: project, language: 'ab-cd' }
    let!(:alt_content){ create :project_content, project: project, language: 'wx-yz' }
    before(:each){ project.reload }
  end

  describe '#content_for' do
    include_context 'fast_serializer_project_contents'
    subject{ serializer.content_for project }

    context 'with the primary language' do
      it{ is_expected.to have_attributes language: 'ab-cd' }
    end

    context 'with an alternate language' do
      let(:params){ { language: 'wx-yz' } }
      it{ is_expected.to have_attributes language: 'wx-yz' }
    end
  end

  describe '#find_content_for' do
    include_context 'fast_serializer_project_contents'
    let(:language){ }
    subject{ serializer.find_content_for project, language }

    context 'with a non-existant language' do
      it{ is_expected.to be_nil }
    end

    context 'with a valid language' do
      let(:language){ 'ab-cd' }
      it{ is_expected.to have_attributes language: 'ab-cd' }
    end
  end
end
