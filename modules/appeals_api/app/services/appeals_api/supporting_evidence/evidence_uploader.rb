# frozen_string_literal: true

module AppealsApi
  module SupportingEvidence
    class EvidenceUploader
      VALID_EVIDENCE_TYPES = %i[notice_of_disagreement].freeze

      def initialize(appeal, document, type:, doc_type: '10')
        @appeal = appeal
        @document = document
        @type = type
        @doc_type = doc_type
        raise ArgumentError, 'invalid type' unless valid_type?
      end

      def process!
        generate_evidence_submission!
        uploader.store!(document)
        update_submission!
        kickoff_vbms_upload_job

        submission
      end

      private

      attr_accessor :submission, :document, :appeal, :type, :doc_type

      def generate_evidence_submission!
        @submission = appeal.evidence_submissions.create!
      end

      def uploader
        @uploader ||= TemporaryStorageUploader.new(appeal.id, type)
      end

      def update_submission!
        @submission.update!(
          status: 'processing',
          file_data: {
            filename: uploader.filename,
            doc_type: doc_type
          }
        )
      end

      def kickoff_vbms_upload_job
        AppealsApi::VBMSUploadWorker.perform_async(submission.id)
      end

      def valid_type?
        type.in?(VALID_EVIDENCE_TYPES)
      end
    end
  end
end
