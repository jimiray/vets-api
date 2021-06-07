# frozen_string_literal: true

module AppealsApi
  module HlrFieldsFormattable
    extend ActiveSupport::Concern

    def birth_date
      self.class.date_from_string birth_date_string
    end

    def veteran_phone
      AppealsApi::HigherLevelReview::Phone.new veteran&.dig('phone')
    end

    def informal_conference_rep_name
      informal_conference_rep&.dig('name')
    end

    def informal_conference_rep_phone
      AppealsApi::HigherLevelReview::Phone.new informal_conference_rep&.dig('phone')
    end

    def veterans_local_time
      veterans_timezone ? Time.now.in_time_zone(veterans_timezone) : Time.now.utc
    end

    def veterans_timezone
      veteran&.dig('timezone').presence&.strip
    end

    def address_combined
      return unless veteran.dig('address', 'addressLine1')

      @address_combined ||= [veteran.dig('address', 'addressLine1'),
                             veteran.dig('address', 'addressLine2'),
                             veteran.dig('address', 'addressLine3')].compact.map(&:strip).join(' ')
      end
  end
end
