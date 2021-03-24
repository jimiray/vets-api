# frozen_string_literal: true

require 'sidekiq'
require 'appeals_api/sidekiq_retry_notifier'
require 'sidekiq/monitored_worker'
require 'appeals_api/sidekiq_retry_notifier'

module AppealsApi
  class VBMSUploadWorker
    include Sidekiq::Worker
    include Sidekiq::MonitoredWorker

    def perform(submission_id)
      submission = AppealsApi::EvidenceSubmission.find(submission_id)

      begin
        SupportingEvidence::VBMSConnectUploader.new(submission).process!
      rescue VBMS::Unknown
        process_vbms_error
      rescue Errno::ENOENT
        process_file_not_found
      end
    end

    private

    def retry_limits_for_notification
      [6, 10]
    end

    def notify(params)
      AppealsApi::SidekiqRetryNotifier.notify!(params)
    end

    def process_vbms_error
      submission.update!(status: 'failed')
      raise
    end

    def process_file_not_found
      submission.update!(status: 'error')
      raise
    end
  end
end
