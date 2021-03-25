# frozen_string_literal: true

module AppealsApi::V1
  module DecisionReviews
    module NoticeOfDisagreements
      class EvidenceSubmissionsController < AppealsApi::ApplicationController
        skip_before_action :authenticate

        def show
          submissions = AppealsApi::EvidenceSubmission.where(
            supportable_id: params[:id],
            supportable_type: 'AppealsApi::NoticeOfDisagreement'
          )

          serialized = AppealsApi::EvidenceSubmissionSerializer.new(submissions)

          render json: serialized.serializable_hash
        end

        def create
          status, error = AppealsApi::FileValidator.new(params[:document]).call

          if status == :ok
            appeal = AppealsApi::NoticeOfDisagreement.find(params[:uuid])
            submission = AppealsApi::SupportingEvidence::EvidenceUploader.new(
              appeal,
              params[:document],
              type: :notice_of_disagreement,
              doc_type: params[:doc_type],
            ).process!

            render json: { message: status_message[submission.status], document: params[:document],
                           uuid: params[:uuid] }
          else
            render json: { errors: [error] }, status: :unprocessable_entity
          end
        end

        private

        def status_message
          # TODO: i18n?
          {
            's3_failed' => 'The file could not be retrieved from s3',
            's3_error' => 'The file could not be uploaded to s3',
            'vbms_error' => '',
            'vbms_failed' => '',
            'submitted' => 'The document has been successfully submitted!',
            'processing' => 'The document has been accepted by our system and is processing.'
          }
        end
      end
    end
  end
end
