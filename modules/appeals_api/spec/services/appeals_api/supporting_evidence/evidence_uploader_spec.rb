# frozen_string_literal: true

require 'rails_helper'

module AppealsApi
  module SupportingEvidence
    RSpec.describe EvidenceUploader do
      let(:appeal) { create(:notice_of_disagreement) }

      describe '#process!' do
        let(:uploader) { EvidenceUploader.new(appeal, nil, type: :notice_of_disagreement) }

        it 'generates an EvidenceSubmission record' do
          expect(appeal.evidence_submissions.count).to eq(0)

          uploader.process!

          expect(appeal.evidence_submissions.count).to eq(1)
        end

        it 'calls store! for CarrierWave' do
          double = instance_double('TemporaryStorageUploader')
          allow(double).to receive(:store!)
          allow(double).to receive(:filename)
          allow(TemporaryStorageUploader).to receive(:new).and_return(double)

          uploader.process!

          expect(double).to have_received(:store!)
        end

        it 'marks the created submission \'processing\'' do
          uploader.process!
          expect(appeal.evidence_submissions.first.status).to eq('processing')
        end

        it 'stores the doctype' do
          uploader.process!
          expect(appeal.evidence_submissions.first.file_data["doc_type"]).to eq('10')
        end
      end
    end
  end
end
