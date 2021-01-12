# frozen_string_literal: true

require 'rails_helper'
require 'generators/module_component/module_component_generator'
require 'generators/module/module_generator'

RSpec.describe 'ModuleComponent', type: :generator do
  describe 'creates a controller' do
    before(:all) do
      ModuleGenerator.new(['foo']).create_directory_structure
      ModuleComponentGenerator.new(%w[foo controller]).create_component
    end

    after(:all) { FileUtils.rm_rf(Dir[Rails.root.join('modules', 'foo')]) }

    let(:path) { Rails.root.join('modules', 'foo', 'app', 'controllers') }

    it 'creates the module controller file' do
      expect(File.exist?("#{path}/foo/v0/foo_controller.rb")).to be_truthy
    end
  end


  describe 'creates multiple components components' do
  end


  describe 'does not create an invalid component' do
  end

  describe 'it creates the module structure if user selects yes' do
    after(:all) { FileUtils.rm_rf(Dir[Rails.root.join('modules', 'foo')]) }

    let(:path) { Rails.root.join('modules', 'foo') }

    it 'creates the module controller and serializer files' do
      allow_any_instance_of(ModuleComponentGenerator).to receive(:yes?).and_return(true)
      ModuleComponentGenerator.new(%w[foo controller serializer]).create_component
      expect(Dir.exist?(path.to_s)).to be_truthy
      expect(File.exist?("#{path}/app/serializers/foo/v0/foo_serializer.rb")).to be_truthy
    end
  end
end
