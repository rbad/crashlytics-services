require 'spec_helper'
require 'webmock/rspec'

describe Service::ZohoProjects do
  let(:config) do
    {
      :project_id => 'sample_project_id',
      :authtoken => 'sample_authtoken'
    }
  end

  it 'has a title' do
    expect(Service::ZohoProjects.title).to eq('Zoho Projects')
  end

  describe 'schema and display configuration' do
    subject { Service::ZohoProjects }

    it { is_expected.to include_string_field :project_id }
    it { is_expected.to include_string_field :authtoken }
    it { is_expected.to include_page 'Project Information', [:project_id, :authtoken] }
  end

  def stub_api_call(expected_query)
    stub_request(:post, 'https://projectsapi.zoho.com/serviceHook').with(:query => expected_query)
  end

  describe '#receive_verification' do
    let(:expected_query) do
      {
        :authtoken => 'sample_authtoken',
        :pId => 'sample_project_id',
        :pltype => 'chook',
        :payload => { :event => 'verification' }.to_json
      }
    end

    let(:service) { Service::ZohoProjects.new('verification', config) }

    it 'a non-400 response as a success' do
      stub_api_call(expected_query).to_return(:status => 200)

      success, message = service.receive_verification(config, nil)

      expect(service.http.ssl[:verify]).to be true # mark ssl for verification
      expect(success).to be true
      expect(message).to eq('Verification successfully completed')
    end

    it 'escalates a 400 response as a failure' do
      stub_api_call(expected_query).to_return(:status => 400)

      success, message = service.receive_verification(config, nil)

      expect(success).to be false
      expect(message).to eq('Invalid Auth Token/Project ID')
    end
  end

  describe '#receive_issue_impact_change' do
    let(:payload) do
      {
        :title => 'foo title',
        :impact_level => 1,
        :impacted_devices_count => 1,
        :crashes_count => 1,
        :app => {
          :name => 'foo name',
          :bundle_identifier => 'foo.bar.baz'
        }
      }
    end

    let(:expected_query) do
      {
        :authtoken => 'sample_authtoken',
        :pId => 'sample_project_id',
        :pltype => 'chook',
        :payload => { :event => 'issue_impact_change', :payload => payload }.to_json
      }
    end

    let(:service) { Service::ZohoProjects.new('issue_impact_change', config) }

    it 'creates a new issue and return its bug id on success' do
      stub_api_call(expected_query).to_return(:status => 200, :body => 'fake-zoho-bug-id')

      response = service.receive_issue_impact_change(config, payload)

      expect(service.http.ssl[:verify]).to be true # mark ssl for verification
      expect(response).to eq(:zohoprojects_bug_id => 'fake-zoho-bug-id')
    end

    it 'escalates non-200 response codes as an error' do
      stub_api_call(expected_query).to_return(:status => 400, :body => 'fake-error-body')

      expect {
        service.receive_issue_impact_change(config, payload)
      }.to raise_error('Problem while sending request to Zoho Projects - HTTP status code: 400, body: fake-error-body')
    end
  end
end
