# frozen_string_literal: true

require 'rails_helper'
require ClaimsApi::Engine.root.join('spec', 'support', 'fake_vbms')

module AppealsApi
  module SupportingEvidence
    RSpec.describe VBMSConnectUploader do
      let(:submission) { create(:evidence_submission, file_data: { filename: "filename" }) }

      before do
        @vbms_test_client = FakeVBMS.new
        allow(VBMS::Client).to receive(:from_env_vars).and_return(@vbms_test_client)
      end


      describe 'process!' do
        it 'initializes an upload through vbms connect' do
          uploader = VBMSConnectUploader.new(submission)

          allow(uploader).to receive(:get_filepath).and_return("filename")
          allow(uploader).to receive(:content_hash).and_return("content_hash")
          allow(uploader).to receive(:filepath).and_return("filename_path")

          uploader.process!

          expect(VBMS::Requests::InitializeUpload).to receive(:new)
        end

        it 'uses the initialize upload to perform an upload' do
          uploader = VBMSConnectUploader.new(submission)

          allow(uploader).to receive(:get_filepath).and_return("filename")
          allow(uploader).to receive(:content_hash).and_return("content_hash")
          allow(uploader).to receive(:filepath).and_return("filename_path")

          #mock response

          uploader.process!

          expect(VBMS::Requests::UploadDocument).to receive(:new)
        end
      end

      def token_response_mock
        OpenStruct.new(upload_token: '<{573F054F-E9F7-4BF2-8C66-D43ADA5C62E7}')
      end

      def document_response_mock
        OpenStruct.new(upload_document_response: {
          '@new_document_version_ref_id' => '{52300B69-1D6E-43B2-8BEB-67A7C55346A2}',
          '@document_series_ref_id' => '{A57EF6CC-2236-467A-BA4F-1FA1EFD4B374}'
        }.with_indifferent_access)
      end
    end
  end
end

