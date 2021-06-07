# frozen_string_literal: true

module AppealsApi
  class HlrModelValidations
    INFORMAL_CONFERENCE_REP_NAME_AND_PHONE_NUMBER_MAX_LENGTH = 100

    def initialize(higher_level_review)
      @hlr = higher_level_review
    end

    def call
      validate_veteran_phone_length
      validate_birth_date_is_a_date
      validate_birth_date_is_in_the_past
      validate_conference_rep_name_number_length
      validate_contestable_issue_dates

      errors.empty? ? true : false
    end

    def validate_veteran_phone_length
      #why are we doing this?
      phone = @hlr.send(:veteran_phone)

      add_error(phone.too_long_error_message) if phone.too_long?
    end

    def validate_conference_rep_name_number_length
      return if @hlr.api_version == 'V2'
      add_error(conference_rep_length_error) if conference_rep_name_and_phone_number_too_long?
    end

    def conference_rep_name_and_phone_number_too_long?
      @hlr.informal_conference_rep_name_and_phone_number.length > INFORMAL_CONFERENCE_REP_NAME_AND_PHONE_NUMBER_MAX_LENGTH
    end

    def conference_rep_length_error
      [
          'Informal conference rep will not fit on form',
          "(#{INFORMAL_CONFERENCE_REP_NAME_AND_PHONE_NUMBER_MAX_LENGTH} char limit):",
          @hlr.informal_conference_rep_name_and_phone_number
      ].join(' ')
    end

    def birth_date
      @birth_date = @hlr.send(:birth_date)
    end

    def validate_birth_date_is_a_date
      add_error("Veteran birth date isn't a date: #{@hlr.send(:birth_date_string).inspect}") unless birth_date
    end

    def validate_birth_date_is_in_the_past
      return unless birth_date

      add_error("Veteran birth date isn't in the past: #{birth_date}") unless AppealsApi::HigherLevelReview.past? birth_date
    end

    def validate_contestable_issue_dates
      return unless @hlr.contestable_issues

      @hlr.contestable_issues.each_with_index do |ci, index|
        decision_date_is_valid(ci&.dig('attributes', 'decisionDate').to_s, index)
      end
    end

    def decision_date_is_valid(string, issue_index)
      date = AppealsApi::HigherLevelReview.date_from_string(string)
      unless date
        not_a_date_error(string, issue_index)
        return
      end
      date_is_not_in_the_past_error(date, issue_index) unless AppealsApi::HigherLevelReview.past? date
    end

    def not_a_date_error(decision_date_string, issue_index)
      add_decision_date_error "isn't a valid date: #{decision_date_string.inspect}", issue_index
    end

    def date_is_not_in_the_past_error(decision_date, issue_index)
      add_decision_date_error "isn't in the past: #{decision_date}", issue_index
    end

    def add_decision_date_error(string, issue_index)
      add_error "included[#{issue_index}].attributes.decisionDate #{string}"
    end

    private

    def add_error(message)
      @hlr.errors.add(:base, message)
    end

    def errors
      @hlr.errors.full_messages
    end
  end
end

