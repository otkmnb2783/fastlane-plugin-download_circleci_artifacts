module Fastlane
  module Actions
    module SharedValues
      RECENT_BUILDS = :RECENT_BUILDS
    end

    class GetRecentBuildsAction < Action
      def self.run(params)
        Actions.verify_gem!('circleci')
        require 'circleci'
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
        project = CircleCi::Project.new @user, @repository
        res = project.recent_builds
        body = res.body.map do |e|
          build = {
            version: e['platform'].to_i,
            num: e['build_num'],
            finish_time: e['stop_time'],
            branch: e['branch'],
            subject: e['subject'],
            committer: e['committer_name'],
            status: e['status']
          }
          workflows = e['workflows']
          build[:workflow_name] = !workflows.nil? ? workflows['workflow_name'] : "-"
          build[:job_name] = !workflows.nil? ? workflows['job_name'] : "-"
          build
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
