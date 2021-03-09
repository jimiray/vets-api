# frozen_string_literal: true

module BGS
  class AuthHeaders
    def initialize(user)
      @user = user
    end

    def to_h
      @headers ||= { 'va_bgs_authorization' => auth_json }
    end

    private

    def auth_json
      {
        external_uid: @user.ssn,
        external_key: @user.ssn
      }.to_json
    end
  end
end
