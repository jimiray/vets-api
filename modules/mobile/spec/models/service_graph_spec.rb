# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mobile::ServiceGraph, type: :model do
  subject do
    Mobile::ServiceGraph.new(
      %i[bgs evss],
      %i[iam_ssoe auth],
      %i[mpi auth],
      %i[mpi evss],
      %i[arcgis facility_locator],
      %i[auth auth_dslogon],
      %i[auth auth_idme],
      %i[auth auth_mhv],
      %i[caseflow appeals],
      %i[dslogon auth_dslogon],
      %i[emis military_service_history],
      %i[evss claims],
      %i[evss direct_deposit_benefits],
      %i[evss letters_and_documents],
      %i[idme auth_idme],
      %i[mhv auth_mhv],
      %i[mhv secure_messaging],
      %i[vaos appointments],
      %i[vet360 user_profile_update]
    )
  end

  describe '#initialize' do
    it 'has registers services as Mobile::ServiceNode instances' do
      expect(subject.services[:bgs]).to be_a(Mobile::ServiceNode)
    end

    it 'adds multiple service nodes to the list' do
      expect(subject.services.size).to eq(25)
    end
  end

  describe '#affected_services' do
    it 'finds the api services (leaves) that are downstream from the queried node' do
      expect(subject.affected_services(:bgs)).to eq(%i[claims direct_deposit_benefits letters_and_documents])
    end

    it 'does not include upstream services in the list' do
      expect(subject.affected_services(:bgs)).not_to include(%i[bgs evss])
    end
  end
end
