# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mobile::ServiceGraph, type: :model do
  describe '#add_service' do
    let(:bgs_service_node) { Mobile::ServiceNode.new(name: :bgs) }
    let(:mpi_service_node) { Mobile::ServiceNode.new(name: :mpi) }
    let(:evss_service_node) { Mobile::ServiceNode.new(name: :evss) }
    
    it 'adds a service node to the list' do
      subject.add_service(bgs_service_node)
      expect(subject.services[:bgs]).to eq(bgs_service_node)
    end

    it 'adds multiple service nodes to the list' do
      subject.add_service(mpi_service_node)
      subject.add_service(evss_service_node)
      expect(subject.services.size).to eq(2)
    end
  end

  describe '#link_service' do
    let(:bgs_service_node) { Mobile::ServiceNode.new(name: :bgs) }
    let(:evss_service_node) { Mobile::ServiceNode.new(name: :evss) }
    
    before do
      subject.add_service(bgs_service_node)
      subject.add_service(evss_service_node)
    end
  
    it 'links the upstream service to the downstream service' do
      subject.link_service(:bgs, :evss)
      expect(bgs_service_node.dependent_services.first.name).to eq(:evss)
    end
  end

  describe '#downstream_services_from' do
    let(:bgs_service_node) { Mobile::ServiceNode.new(name: :bgs) }
    let(:evss_service_node) { Mobile::ServiceNode.new(name: :evss) }
    let(:letters_service_node) { Mobile::ServiceNode.new(name: :letters_and_documents, part_of_api: true) }
    let(:direct_deposit_service_node) { Mobile::ServiceNode.new(name: :direct_deposit_benefits, part_of_api: true) }
    let(:claims_service_node) { Mobile::ServiceNode.new(name: :claims, part_of_api: true) }
  
    before do
      subject.add_service(bgs_service_node)
      subject.add_service(evss_service_node)
      subject.add_service(letters_service_node)
      subject.add_service(direct_deposit_service_node)
      subject.add_service(claims_service_node)

      subject.link_service(:bgs, :evss)
      subject.link_service(:evss, :letters_and_documents)
      subject.link_service(:evss, :direct_deposit_benefits)
      subject.link_service(:evss, :claims)
    end
  
    it 'finds the api services that are downstream from the queried service' do
      expect(subject.downstream_services_from(:bgs)).to eq([:letters_and_documents, :direct_deposit_benefits, :claims])
    end

    it 'does not include non api services in the list' do
      expect(subject.downstream_services_from(:bgs)).to_not include([:bgs, :evss])
    end
  end
end
