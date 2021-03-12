# frozen_string_literal: true

module HealthQuest
  class JwtWrapper
    VERSION = 2.1
    ISS = 'gov.va.clipboard'
    ID_TYPE = 'ICN'
    AUTHORITY = 'gov.va.iam.ssoe.v1'

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def token
      JWT.encode(payload, Configuration.instance.rsa_key, 'RS512')
    end

    private

    def payload
      {
        authenticated: true,
        sub: user.icn,
        idType: ID_TYPE,
        iss: ISS,
        firstName: user.first_name_mpi,
        lastName: user.last_name_mpi,
        authenticationAuthority: AUTHORITY,
        jti: SecureRandom.uuid,
        nbf: 1.minute.ago.to_i,
        exp: 15.minutes.from_now.to_i,
        sst: 1.minute.ago.to_i + 50,
        version: VERSION,
        gender: gender,
        dob: user.birth_date,
        dateOfBirth: user.birth_date,
        edipid: user.edipi_mpi,
        ssn: user.ssn_mpi
      }
    end

    def gender
      type = user.gender_mpi
      return '' unless type.is_a?(String)

      case type.upcase[0, 1]
      when 'M'
        'MALE'
      when 'F'
        'FEMALE'
      end
    end
  end
end