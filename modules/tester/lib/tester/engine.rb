# frozen_string_literal: true

module Tester
  class Engine < ::Rails::Engine
    isolate_namespace Tester
    config.generators.api_only = true
  end
end
