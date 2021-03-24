# frozen_string_literal: true

require 'rails_helper'

module AppealsApi
  module SupportingEvidence
    RSpec.describe VBMSConnectUploader do
      let(:submission) { create(:evidence_submission, file_data: { filename: "filename" }) }

      describe 'process!' do
        it 'initializes an upload through vbms connect' do
          allow(VBMS::Requests::InitializeUpload).to receive(:new)

          uploader = VBMSConnectUploader.new(submission)

          allow(uploader).to receive(:get_filepath).and_return("filename")
          allow(uploader).to receive(:content_hash).and_return("content_hash")
          allow(uploader).to receive(:filepath).and_return("filename_path")

          uploader.process!

          expect(VBMS::Requests::InitializeUpload).to receive(:new)
        end

        it 'uses the initialize upload to perform an upload' do

        end

        it 'returns a doc ref_id and series ref_id' do

        end
      end
    end
  end
end

