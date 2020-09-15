# frozen_string_literal: true

module Debts
  class LetterDownloader
    DEBTS_DOCUMENT_TYPES = %w[
      193
      194
      1213
      1214
      1215
      1216
      1217
      1287
      1334
    ].freeze

    def initialize(user)
      @user = user
      @client = VBMS::Client.from_env_vars(env_name: Settings.vbms.env)
      @service = debts_service
      verify_no_dependent_debts
    end

    def get_letter(document_id)
      verify_letter_in_folder(document_id)

      @client.send_request(
        VBMS::Requests::GetDocumentContent.new(document_id)
      ).content
    end

    def list_letters
      debts_records = @client.send_request(
        VBMS::Requests::FindDocumentVersionReference.new(@service.file_number)
      ).find_all do |record|
        DEBTS_DOCUMENT_TYPES.include?(record.doc_type)
      end

      debts_records.map do |debts_record|
        debts_record.marshal_dump.slice(
          :document_id, :doc_type, :type_description, :received_at
        )
      end
    end

    private

    def debts_service
      Debts::Service.new(@user)
    end

    def verify_no_dependent_debts
      raise Common::Exceptions::Unauthorized if @service.veteran_has_dependent_debts?
    end

    def verify_letter_in_folder(document_id)
      raise Common::Exceptions::Unauthorized unless list_letters.any? do |letter|
        letter[:document_id] == document_id
      end
    end
  end
end
