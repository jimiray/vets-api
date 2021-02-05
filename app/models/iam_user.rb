# frozen_string_literal: true

require 'digest'
require 'active_support/core_ext/digest/uuid'

# Subclasses the `User` model. Adds a unique redis namespace for IAM users.
# Adds IAM sourced versions of ICN, EDIPI, and SEC ID and methods to use them
# or hit MPI via the va_profile method.
#
class IAMUser < ::User
  redis_store REDIS_CONFIG[:iam_user][:namespace]
  redis_ttl REDIS_CONFIG[:iam_user][:each_ttl]
  redis_key :uuid

  attribute :expiration_timestamp, Integer
  attribute :iam_icn, String
  attribute :iam_edipi, String
  attribute :iam_sec_id, String
  attribute :iam_mhv_id, String

  # MPI::Service uses 'mhv_icn' to query by icn rather than less accurate user traits
  alias mhv_icn iam_icn
  alias mhv_correlation_id iam_mhv_id

  # Builds an user instance from a IAMUserIdentity
  #
  # @param iam_identity [IAMUserIdentity] the IAM identity object.
  # @return [IAMUser] an instance of this class
  #
  def self.build_from_user_identity(user_identity)
    user = new(user_identity.attributes)
    user.set_expire
    user
  end

  # Where to get the edipi from
  # If iam_edipi available return that otherwise hit MVI
  # @return [String] the users DoD EDIPI
  #
  def edipi
    loa3? && iam_edipi.present? ? iam_edipi : mpi&.edipi
  end

  # for PII reasons we don't send correlation ids over the wire
  # but JSON API requires an id with each resource
  #
  def id
    Digest::UUID.uuid_v5(last_name, email)
  end

  def identity
    @identity ||= IAMUserIdentity.find(uuid)
  end

  def sec_id
    identity.iam_sec_id || va_profile&.sec_id
  end

  def mhv_account_type
    MHVAccountTypeService.new(self).mhv_account_type
  end

  # This is not the correct way of determining a VA patient
  # It should be based on presence of treating facilities like in 
  # the parent class, which means we need to extract the list of facilities
  # from the IAM introspection payload.
  # But if we are only going to enable SM for existing premium users then 
  # this is a safe approach for enabling the pundit policy to succeed.
  def va_patient?
    mhv_correlation_id.present?
  end

  def set_expire
    redis_namespace.expireat(REDIS_CONFIG[:iam_user][:namespace], expiration_timestamp)
  end
end
