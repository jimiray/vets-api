# frozen_string_literal: true

require 'rails_helper'

module AppealsApi
  describe VBMSUploadWorker, type: :job do

    describe '#perform' do
      let(:submission) { create(:evidence_submission) }

      it 'calls VBMSConnectUploader' do
        connect_uploader = instance_double(SupportingEvidence::VBMSConnectUploader)
        allow(SupportingEvidence::VBMSConnectUploader).to receive(:new).and_return(connect_uploader)
        allow(connect_uploader).to receive(:process!)
        expect(SupportingEvidence::VBMSConnectUploader).to receive(:new)
        expect(connect_uploader).to receive(:process!)

        described_class.new.perform(submission.id)
      end

      it 'updates the submission on s3 failure' do
        connect_uploader = instance_double(SupportingEvidence::VBMSConnectUploader)
        allow(SupportingEvidence::VBMSConnectUploader)
          .to receive(:new).with(submission).and_return(connect_uploader)
        allow(connect_uploader).to receive(:process!).and_raise(Errno::ENOENT)

        begin
          expect{ described_class.new.perform(submission.id) }
            .to change(submission, :status).from('pending').to('failed')
        rescue Errno::ENOENT
        end
      end

      it 'updates the submission on vbms failure' do
        connect_uploader = instance_double(SupportingEvidence::VBMSConnectUploader)
        allow(SupportingEvidence::VBMSConnectUploader)
          .to receive(:new).with(submission).and_return(connect_uploader)
        allow(connect_uploader).to receive(:process!).and_raise(VBMS::Unknown.new('', ''))

        begin
          expect{ described_class.new.perform(submission.id) }
            .to change(submission, :status).from('pending').to('error')
        rescue VBMS::Unknown
        end
      end
    end
  end
end
