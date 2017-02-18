require 'circleci'

module Fastlane
  module Actions
    class ShowBuildsAction < Action
      def self.run(params)
        builds = GetRecentBuildsAction.run(params)
        table = Helper::DownloadCircleciArtifactsHelper.convert_to(builds)
        puts table
      end

      #####################################################
      # @!group Documentation
      #####################################################
      def self.description
        "This action show recent builds a Circle CI artifact's using the Circle CI API"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                  env_name: "CIRCLECI_TOKEN",
                               description: "API Token for Circle CI",
                                      type: String,
                                  optional: true),
          FastlaneCore::ConfigItem.new(key: :user_name,
                                  env_name: "CIRCLECI_USER_NAME",
                               description: "user name for Circle CI",
                                      type: String,
                                  optional: true),
          FastlaneCore::ConfigItem.new(key: :repository,
                                  env_name: "CIRCLECI_REPOSITORY",
                               description: "repository for Circle CI",
                                      type: String,
                                  optional: true)
        ]
      end

      def self.authors
        ["Manabu OHTAKE"]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end
