# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application Directory Endpoint', type: :request do
  describe '#get /services/apps/v0/directory' do
    it 'returns a populated list of applications' do
      get '/services/apps/v0/directory'
      body = JSON.parse(response.body)
      expect(body).not_to be_empty
    end
  end
  let(:valid_headers) do
    { 'Authorization' => Settings.directory.secret }
  end
  let(:invalid_headers) do
    { 'Authorization' => 'somethingwrong'}
  end
  let(:valid_params) do
    {
      "name":"testing",
      "logo_url":"www.example.com/image2",
      "service_categories": ["Health"],
      "app_type":"Third-Party-OAuth",
      "platforms":["iOS"],
      "app_url":"www.example.com",
      "description":"This is the testing description",
      "privacy_url":"www.example.com/privacy",
      "tos_url":"www.example.com/tos"
    }
  end
  let(:invalid_params) do
    {
      # missing required variables
      "name":"testing",
      "platforms":["iOS"],
      "app_url":"www.example.com",
      "description":"This is the testing description",
      "privacy_url":"www.example.com/privacy",
      "tos_url":"www.example.com/tos"
    }
  end

  describe '#put /services/apps/v0/directory/:name' do
    it 'updates the app' do
      post '/services/apps/v0/directory', :params => { :id=> 'testing',:directory_application => valid_params }, :headers => valid_headers

      put '/services/apps/v0/directory', :params => { :id=> 'testing',:directory_application => valid_params }, :headers => valid_headers
      body = JSON.parse(response.body)
      expect(body.length).to be(1)
    end
  end

  describe '#destroy /services/apps/v0/directory/:name' do
    it 'returns unauthorized if the header is invalid' do
      post '/services/apps/v0/directory', :params => { :id=> 'testing',:directory_application => valid_params }, :headers => valid_headers
      delete '/services/apps/v0/directory/testing', :params => { :id=>'testing'  }, :headers => invalid_headers
      expect(response).to have_http_status(:unauthorized)

    end
    it 'deletes the app' do
      post '/services/apps/v0/directory', :params => { :id=> 'testing',:directory_application => valid_params }, :headers => valid_headers
      delete '/services/apps/v0/directory/testing', :params => { :id=>'testing'  }, :headers => valid_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#create /services/apps/v0/directory' do
    it 'creates the app' do
      post '/services/apps/v0/directory', :params => { :id=>'testing',:directory_application => valid_params }, :headers => valid_headers

    end
  end

  describe '#get /services/apps/v0/directory/:name' do
    it 'sets the instance variable correctly' do
      get '/services/apps/v0/directory', :params=> {:id=>'iBlueButton'}

    end
    it 'returns a single application' do
      get '/services/apps/v0/directory/Apple%20Health'
      body = JSON.parse(response.body)
      expect(body.length).to be(1)
    end
    it 'returns an app when passing the :name param' do
      get '/services/apps/v0/directory/iBlueButton'
      body = JSON.parse(response.body)
      expect(body).not_to be_empty
    end
  end

  describe '#get /services/apps/v0/directory/scopes/:category' do
    it 'returns a populated list of health scopes' do
      VCR.use_cassette('okta/health-scopes', :match_requests_on => %i[method path]) do
        get '/services/apps/v0/directory/scopes/Health'
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(body).not_to be_empty
        expect(body['data'][0]['name']).to eq('launch/patient')
      end
    end
    it 'returns a populated list of benefits scopes' do
      VCR.use_cassette('okta/benefits-scopes', :match_requests_on => %i[method path]) do
        get '/services/apps/v0/directory/scopes/Benefits'
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(body).not_to be_empty
        expect(body['data'][0]['name']).to eq('claim.read')
      end
    end
    it 'returns a populated list of verification scopes' do
      VCR.use_cassette('okta/verification-scopes', :match_requests_on => %i[method path]) do
        get '/services/apps/v0/directory/scopes/Verification'
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:success)
        expect(body).not_to be_empty
        expect(body['data'][0]['name']).to eq('disability_rating.read')
      end
    end
    it 'returns an empty list when given an unknown category' do
      VCR.use_cassette('okta/verification-scopes', :match_requests_on => %i[method path]) do
        get '/services/apps/v0/directory/scopes/unknown_category'
        expect(response).to have_http_status(:no_content)
      end
    end
    it '204s when given a null category' do
      VCR.use_cassette('okta/verification-scopes', :match_requests_on => %i[method path]) do
        get '/services/apps/v0/directory/scopes'
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
