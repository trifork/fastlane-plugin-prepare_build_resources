module Fastlane
  module Helper
    class PrepareBuildResourcesHelper
      # class methods that you define here become available in your action
      # as `Helper::PrepareBuildResourcesHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the prepare_build_resources plugin helper!")
      end
    end
  end
end
