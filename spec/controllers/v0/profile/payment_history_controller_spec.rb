# frozen_string_literal: true

require 'rails_helper'

# outputs debug line in specs
# "D, [2021-01-14T20:11:20.985266 #29] DEBUG -- : HTTPI /peer GET request to internal-dsva-vagov-dev-fwdproxy-1893365470.us-gov-west-1.elb.amazonaws.com (net_http)\n"

RSpec.describe V0::Profile::PaymentHistoryController, type: :controller do
  let(:user) { create(:evss_user) }

  describe '#index' do
    context 'with a valid bgs response' do
      it 'returns true if a logged-in user has a valid va file number' do
        VCR.use_cassette('bgs/payment_history/retrieve_payment_summary_with_bdn') do
          sign_in_as(user)
          get(:index)

          expect(response.code).to eq('200')
          expect(response).to have_http_status(:ok)
          # not using "eq" for these counts in case additional payments are added for this user
          expect(JSON.parse(response.body)['data']['attributes']['payments'].count).to be >= 47
          expect(JSON.parse(response.body)['data']['attributes']['return_payments'].count).to be >= 0
        end
      end
    end
  end
end
