# frozen_string_literal: true

module V0
  module Profile
    class ValidVaFileNumbersController < ApplicationController
      # before_action { authorize :bgs, :access? }

      def show
        render json: {
          'data': {
            'id': '',
            'type': 'valid_va_file_number',
            'attributes': {
              'valid_va_file_number': true
            }
          }
        }.to_json
      end

      private

      def valid_va_file_number_data(service_response)
        return { file_nbr: true } if service_response[:file_nbr].present?

        { file_nbr: false }
      end
    end
  end
end
