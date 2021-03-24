# frozen_string_literal: true

module AppealsApi
  module SupportingEvidence
    class VBMSConnectUploader
      def initialize(submission)
        @submission = submission
      end

      def process!
        upload_token_response = vbms_connect_upload_token_request
        upload_response = send_document(upload_token_response.upload_token)

        {
          vbms_new_document_version_ref_id: upload_response.upload_document_response[:@new_document_version_ref_id],
          vbms_document_series_ref_id: upload_response.upload_document_response[:@document_series_ref_id]
        }
      end

      private

      attr_accessor :submission

      def vbms_connect_upload_token_request
        vbms_request = VBMS::Requests::InitializeUpload.new(
          content_hash: content_hash,
          filename: filename,
          file_number: file_number,
          va_receive_date: Time.zone.now,
          doc_type: doc_type,
          source: 'BVA',
          subject: doc_type,
          new_mail: true
        )
        client.send_request(vbms_request)
      end

      def send_document(upload_token)
        upload_request = VBMS::Requests::UploadDocument.new(
          upload_token: upload_token,
          filepath: filepath
        )
        client.send_request(upload_request)
      end

      def client
        @client ||= VBMS::Client.from_env_vars(env_name: Settings.vbms.env)
      end

      def filepath
        @filepath ||= get_filepath
      end

      def file_number
        submission.supportable.ssn
      end

      def content_hash
        Digest::SHA1.hexdigest(File.read(filepath))
      end

      def filename
        SecureRandom.uuid + File.basename(filepath)
      end

      def submission_type
        submission.supportable_type.demodulize.underscore.to_sym
      end

      def submission_appeal_guid
        submission.supportable_id
      end

      def doc_type
        {
          notice_of_disagreement: '',
          supplemental_claim: ''
        }[submission_type]
      end

      def get_filepath
        uploader = TemporaryStorageUploader.new(submission_appeal_guid, submission_type)
        uploader.retrieve_from_store!(submission.file_data['filename'])

        return uploader.file.file unless Settings.modules_appeals_api.s3.uploads_enabled

        stream = URI.parse(uploader.file.url).open
        # stream could be a Tempfile or a StringIO https://stackoverflow.com/a/23666898
        stream.try(:path) || stream_to_temp_file(stream).path
      end

      def stream_to_temp_file(stream, close_stream: true)
        file = Tempfile.new
        file.binmode
        file.write stream.read
        file
      ensure
        file.flush
        file.close
        stream.close if close_stream
      end
    end
  end
end
