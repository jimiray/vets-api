# frozen_string_literal: true

require 'mpi/responses/find_profile_response'
require 'mpi/service'
require 'mpi/orch_search_service'
require 'common/models/redis_store'
require 'common/models/concerns/cache_aside'
require 'mpi/constants'

# Facade for MVI. User model delegates MVI correlation id and VA profile (golden record) methods to this class.
# When a profile is requested from one of the delegates it is returned from either a cached response in Redis
# or from the MVI SOAP service.
class MPIData < Common::RedisStore
  include Common::CacheAside

  REDIS_CONFIG_KEY = :mpi_profile_response
  redis_config_key REDIS_CONFIG_KEY

  # @return [UserIdentity] the user identity object to query MVI for.
  attr_accessor :user_identity

  # Creates a new MPIData instance for a user identity.
  #
  # @param user [UserIdentity] the user identity to query MVI for
  # @return [MPIData] an instance of this class
  def self.for_user(user_identity)
    mvi = MPIData.new
    mvi.user_identity = user_identity
    mvi
  end

  # Queries MPI specifically to retrieve historical icn data.
  #
  # @param user [User] the user to query MVI for
  # @return [MPIData] an instance of this class
  def self.historical_icn_for_user(user_identity)
    return nil unless user_identity.loa3?

    mpi_data_instance = MPIData.new
    mpi_data_instance.user_identity = user_identity
    mpi_data_instance.mvi_get_person_historical_icns
  end

  # A DOD EDIPI (Electronic Data Interchange Personal Identifier) MVI correlation ID
  # or nil for users < LOA 3
  #
  # @return [String] the edipi correlation id
  delegate :edipi, to: :profile, allow_nil: true

  # A ICN (Integration Control Number - generated by the Master Patient Index) MVI correlation ID
  # or nil for users < LOA 3
  #
  # @return [String] the icn correlation id
  delegate :icn, to: :profile, allow_nil: true

  # A ICN (Integration Control Number - generated by the Master Patient Index) MVI correlation ID
  # combined with its Assigning Authority ID.  Or nil for users < LOA 3.
  #
  # @return [String] the icn correlation id with its assigning authority id.
  #   For example:  '12345678901234567^NI^200M^USVHA^P'
  #
  delegate :icn_with_aaid, to: :profile, allow_nil: true

  # A MHV (My HealtheVet) MVI correlation id
  # or nil for users < LOA 3
  #
  # @return [String] the mhv correlation id
  delegate :mhv_correlation_id, to: :profile, allow_nil: true

  # A VBA (Veterans Benefits Administration) or participant MVI correlation id.
  #
  # @return [String] the participant id
  delegate :participant_id, to: :profile, allow_nil: true

  # A BIRLS (Beneficiary Identification and Records Locator System) MVI correlation id.
  #
  # @return [String] the birls id
  delegate :birls_id, to: :profile, allow_nil: true

  # A Vet360 Correlation ID
  #
  # @return [String] the Vet360 id
  delegate :vet360_id, to: :profile, allow_nil: true

  # The search token given in the original MVI 1306 response message
  #
  # @return [String] the search token
  delegate :search_token, to: :profile, allow_nil: true

  # A Cerner ID
  #
  # @return [String] the Cerner id
  delegate :cerner_id, to: :profile, allow_nil: true

  # The user's Cerner facility ids
  #
  # @return [Array[String]] the the list of Cerner facility ids
  delegate :cerner_facility_ids, to: :profile

  # Identity theft flag
  #
  # @return [Boolean] presence or absence of identity theft flag
  delegate :id_theft_flag, to: :profile

  # The profile returned from the MVI service. Either returned from cached response in Redis or the MVI service.
  #
  # @return [MPI::Models::MviProfile] patient 'golden record' data from MVI
  def profile
    return nil unless user_identity.loa3?

    mvi_response&.profile
  end

  # The status of the last MVI response or not authorized for for users < LOA 3
  #
  # @return [String] the status of the last MVI response
  def status
    return MPI::Responses::FindProfileResponse::RESPONSE_STATUS[:not_authorized] unless user_identity.loa3?

    mvi_response.status
  end

  # The error experienced when reaching out to the MVI service.
  #
  # @return [Common::Exceptions::BackendServiceException]
  def error
    return Common::Exceptions::Unauthorized.new(source: self.class) unless user_identity.loa3?

    mvi_response.try(:error)
  end

  # @return [MPI::Responses::FindProfileResponse] the response returned from MVI
  def mvi_response
    @mvi_response ||= response_from_redis_or_service
  end

  # @return [String] Array representing the historical icn data for the user
  def mvi_get_person_historical_icns
    mpi_profile = mpi_service.find_profile(user_identity, search_type: MPI::Constants::CORRELATION_WITH_ICN_HISTORY)
    mpi_profile&.profile&.historical_icns
  end

  # The status of the MPI Add Person call. An Orchestrated MVI Search needs to be made before an MPI add person
  # call is made. The response is recached afterwards so the new ids can be accessed on the next call.
  #
  # @return [MPI::Responses::AddPersonResponse] the response returned from MPI Add Person call
  def add_person(user_identity)
    search_response = MPI::OrchSearchService.new.find_profile(user_identity)
    if search_response.ok?
      @mvi_response = search_response
      add_response = mpi_service.add_person(user_identity)
      add_ids(add_response) if add_response.ok?
    else
      add_response = MPI::Responses::AddPersonResponse.with_failed_orch_search(
        search_response.status, search_response.error
      )
    end
    add_response
  end

  private

  def add_ids(response)
    # set new ids in the profile and recache the response
    profile.birls_id = response.mvi_codes[:birls_id].presence
    profile.participant_id = response.mvi_codes[:participant_id].presence

    cache(user_identity.uuid, mvi_response) if mvi_response.cache?
  end

  def response_from_redis_or_service
    do_cached_with(key: user_identity.uuid) do
      mpi_service.find_profile(user_identity)
    rescue ArgumentError
      return nil
    end
  end

  def mpi_service
    @service ||= MPI::Service.new
  end

  def save
    saved = super
    expire(record_ttl) if saved
    saved
  end

  def record_ttl
    if status == MPI::Responses::FindProfileResponse::RESPONSE_STATUS[:ok]
      # ensure default ttl is used for 'ok' responses
      REDIS_CONFIG[REDIS_CONFIG_KEY][:each_ttl]
    else
      # assign separate ttl to redis cache for failure responses
      REDIS_CONFIG[REDIS_CONFIG_KEY][:failure_ttl]
    end
  end
end
