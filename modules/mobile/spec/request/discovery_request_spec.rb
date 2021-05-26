# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/iam_session_helper'
require_relative '../support/matchers/json_schema_matcher'

RSpec.describe 'discovery', type: :request do
  include JsonSchemaMatchers
  describe 'GET /mobile' do
    context 'when the mobile_api flipper feature is enabled' do
      let(:expected_body) do
        {
          'data' => {
            'attributes' => {
              'message' => 'Welcome to the mobile API'
            }
          }
        }
      end
    end

    context 'when the mobile_api flipper feature is disabled' do
      before { Flipper.disable('mobile_api') }

      it 'returns a 404' do
        get '/mobile'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /discovery' do
    before { get '/mobile/discovery' }

    let(:response_attributes) { response.parsed_body.dig('data', 'attributes') }

    it 'has an auth_base_url' do
      expect(response_attributes['auth_base_url']).to eq('https://sqa.fed.eauth.va.gov/oauthe/sps/oauth/oauth20/')
    end

    it 'has an auth_base_url' do
      expect(response_attributes['api_root_url']).to eq('https://dev.va.gov/mobile')
    end

    it 'lets the app know the minimum_version supported' do
      expect(response_attributes['minimum_version']).to eq('1.0.0')
    end

    it 'has the expected web views' do
      expect(response_attributes['web_views']).to eq(
        {
          'corona_faq' => 'https://www.va.gov/coronavirus-veteran-frequently-asked-questions',
          'facility_locator' => 'https://www.va.gov/find-locations'
        }
      )
    end

    context 'when no maintenance windows are active' do
      it 'returns an empty array' do
        expect(response_attributes['maintenance_windows']).to eq([])
      end
    end

    context 'when a maintenance with many dependent services is active' do
      before do
        Timecop.freeze('2021-05-25T23:33:39Z')
        FactoryBot.create(:mobile_maintenance_window)
      end

      after { Timecop.return }

      it 'returns an array of those services' do
        get '/mobile/discovery'
        expect(response_attributes['maintenance_windows']).to eq([])
      end
    end
  end
end
