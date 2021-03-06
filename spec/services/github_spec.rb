require 'spec_helper'

describe Service::GitHub do
  let(:config) do
    {
      :access_token => 'foo_access_token',
      :repo => 'crashlytics/sample-project'
    }
  end

  it 'has a title' do
    expect(Service::GitHub.title).to eq('GitHub')
  end

  describe 'schema and display configuration' do
    subject { Service::GitHub }

    it { is_expected.to include_string_field :api_endpoint }
    it { is_expected.to include_string_field :repo }
    it { is_expected.to include_string_field :access_token }

    it { is_expected.to include_page 'Repository', [:repo, :access_token] }
    it { is_expected.to include_page 'GitHub Enterprise', [:api_endpoint] }
  end

  describe '#receive_verification' do
    it 'returns true and a confirmation message on success' do
      service = Service::GitHub.new('verification', {})
      stub_request(:get, 'https://api.github.com/repos/crashlytics/sample-project').
         to_return(:status => 200, :body => '')

      success, message = service.receive_verification(config, nil)
      expect(success).to be true
      expect(message).to eq('Successfully accessed repo crashlytics/sample-project.')
    end

    it 'returns false and an error message on failure' do
      service = Service::GitHub.new('verification', {})
      stub_request(:get, 'https://api.github.com/repos/crashlytics/sample-project').
         to_return(:status => 404, :body => '')

      success, message = service.receive_verification(config, nil)
      expect(success).to be false
      expect(message).to eq('Could not access repository for crashlytics/sample-project.')
    end

    it 'uses the api_endpoint if provided' do
      service = Service::GitHub.new('verification', {})
      stub_request(:get, 'https://github.fabric.io/api/v3/repos/crashlytics/sample-project').
        to_return(:status => 200, :body => '')

      success, message = service.receive_verification(config.merge(:api_endpoint => 'https://github.fabric.io/api/v3/'), nil)
      expect(success).to be true
      expect(message).to eq('Successfully accessed repo crashlytics/sample-project.')
    end
  end

  describe '#receive_issue_impact_change' do
    let(:service) { Service::GitHub.new('issue_impact_change', {}) }
    let(:crashlytics_issue) do
      {
        :url => 'foo_issue_url',
        :app => { :name => 'foo_app_name' },
        :title => 'foo_issue_title',
        :method => 'foo_issue_method',
        :crashes_count => 'foo_issue_crashes_count',
        :impacted_devices_count => 'foo_issue_impacted_devices_count'
      }
    end
    let(:expected_issue_body) do
      "#### in foo_issue_method\n" \
      "\n" \
      "* Number of crashes: foo_issue_crashes_count\n" \
      "* Impacted devices: foo_issue_impacted_devices_count\n" \
      "\n" \
      "There's a lot more information about this crash on crashlytics.com:\n" \
      "[foo_issue_url](foo_issue_url)"
    end

    let(:successful_creation_response) do
      {
        :status => 201,
        :headers => { 'content-type' => 'application/json' },
        :body => { :id => 743, :number => 42 }.to_json
      }
    end

    let(:failed_creation_response) do
      {
        :status => 401,
        :headers => { 'content-type' => 'application/json'},
        :body => { :message => 'GitHub error message' }.to_json
      }
    end

    it 'creates a new GitHub issue' do
      stub_request(:post, 'https://api.github.com/repos/crashlytics/sample-project/issues').
        to_return(successful_creation_response)

      result = service.receive_issue_impact_change(config, crashlytics_issue)
      expect(result).to eq(:github_issue_number => 42)
    end

    it 'creates a new Github issue on an enterprise account if api_endpoint is provided' do
      stub_request(:post, 'https://github.fabric.io/api/v3/repos/crashlytics/sample-project').
        to_return(successful_creation_response)

      result = service.receive_issue_impact_change(config, crashlytics_issue)
      expect(result).to eq(:github_issue_number => 42)
    end

    it 'raises if creating a new GitHub issue fails' do
      stub_request(:post, 'https://api.github.com/repos/crashlytics/sample-project/issues').
        to_return(failed_creation_response)

      expect { service.receive_issue_impact_change config, crashlytics_issue }.
        to raise_error(Octokit::Unauthorized)
    end
  end
end
