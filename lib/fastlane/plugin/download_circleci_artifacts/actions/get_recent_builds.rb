require 'circleci'

module Fastlane
  module Actions
    module SharedValues
      RECENT_BUILDS = :RECENT_BUILDS
    end

    class GetRecentBuildsAction < Action
      def self.run(params)
        configure(params)
        get
      end

      def self.configure(params)
        @token = Helper::DownloadCircleciArtifactsHelper.token(params)
        @user = Helper::DownloadCircleciArtifactsHelper.user_name(params)
        @repository = Helper::DownloadCircleciArtifactsHelper.repository(params)
        @count = Helper::DownloadCircleciArtifactsHelper.recent_build_count(params)
        UI.user_error! "Set CIRCLECI_TOKEN" if @token.nil? || @token.empty?
        UI.user_error! "Set CIRCLECI_USER_NAME" if @user.nil? || @user.empty?
        UI.user_error! "Set CIRCLECI_REPOSITORY" if @repository.nil? || @repository.empty?
        UI.message "Access to #{@user}/#{@repository}"
      end

      def self.get
        res = CircleCi::Project.recent_builds @user, @repository
        body = res.body.map do |e|
          {
            num: e['build_num'],
            branch: e['branch'],
            subject: e['subject'],
            committer: e['committer_name'],
            status: e['status']
          }
        end
        body = body.select { |e| e[:status] == 'success' }
        builds = body[0...@count]
        Actions.lane_context[SharedValues::RECENT_BUILDS] = builds
        builds
      end

      #####################################################
      # @!group Documentation
      #####################################################
      def self.description
        "This action recent builds a Circle CI artifact's using the Circle CI API"
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
                                  optional: true),
          FastlaneCore::ConfigItem.new(key: :recent_build_count,
                                  env_name: "CIRCLECI_RECENT_BUILD_COUNT",
                               description: "get recent build count",
                                      type: Integer,
                                  optional: true)
        ]
      end

      def self.output
        [
          ['RECENT_BUILDS', 'Recent Builds']
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
