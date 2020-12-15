# frozen_string_literal: true

module CovidVaccine
  module V0
    class RawFormData
      include ActiveModel::Validations

      ATTRIBUTES = %w[email zip_code vaccine_interest].freeze
      ZIP_REGEX = /\A^\d{5}(-\d{4})?$\z/.freeze

      attr_accessor(*ATTRIBUTES)

      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :vaccine_interest, presence: true
      validates :zip_code, format: { with: ZIP_REGEX, message: 'should be in the form 12345 or 12345-1234' }

      def initialize(attributes = {})
        attributes.each do |name, value|
          send("#{name}=", value) if name.to_s.in?(ATTRIBUTES)
        end
      end
    end
  end
end