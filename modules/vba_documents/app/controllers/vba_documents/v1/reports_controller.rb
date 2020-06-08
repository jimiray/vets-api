# frozen_string_literal: true

module VBADocuments
  module V1
    class ReportsController < ApplicationController
      skip_before_action(:authenticate)
      before_action :validate_params

      MAX_REPORT_SIZE = 1000
      ID_PARAM = 'ids'

      def create
        statuses = VBADocuments::UploadSubmission.where(guid: params[ID_PARAM])
        render json: with_spoofed(statuses),
               each_serializer: VBADocuments::V1::UploadSerializer
      end

      private

      def with_spoofed(statuses)
        guids = statuses.map(&:guid)
        missing = params[ID_PARAM] - guids
        statuses.to_a + missing.map { |id| VBADocuments::UploadSubmission.fake_status(id) }
      end

      def validate_params
        raise Common::Exceptions::Internal::ParameterMissing, ID_PARAM if params[ID_PARAM].nil?
        unless params[ID_PARAM].is_a?(Array)
          raise Common::Exceptions::Internal::InvalidFieldValue.new(ID_PARAM, params[ID_PARAM])
        end
        raise Common::Exceptions::Internal::InvalidFieldValue.new(ID_PARAM, params[ID_PARAM]) if
          params[ID_PARAM].size > MAX_REPORT_SIZE
      end
    end
  end
end
