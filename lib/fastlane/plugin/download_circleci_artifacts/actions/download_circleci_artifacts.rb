require 'circleci'

module Fastlane
  module Actions
    class DownloadCircleciArtifactsAction < Action
      def self.run(params)
        configure(params)
        get(params)
      end

      def self.configure(params)
        @token = Helper::DownloadCircleciArtifactsHelper.token(params)
        @user = Helper::DownloadCircleciArtifactsHelper.user_name(params)
        @repository = Helper::DownloadCircleciArtifactsHelper.repository(params)
        @file = params[:file]
        @dist = params[:dist]
        UI.user_error! "Set CIRCLECI_TOKEN" if @token.nil? || @token.empty?
        UI.user_error! "Set CIRCLECI_USER_NAME" if @user.nil? || @user.empty?
        UI.user_error! "Set CIRCLECI_REPOSITORY" if @repository.nil? || @repository.empty?
        UI.message "User Name: #{@user}"
        UI.message "Repository: #{@repository}"
        UI.message "File: #{@file}"
        UI.message "dist: #{@dist}"
      end

      def self.get(params)
        builds = GetRecentBuildsAction.run(params)
        num = Helper::DownloadCircleciArtifactsHelper.show(builds)
        res = CircleCi::Build.artifacts @user, @repository, num.to_s
        artifacts = res.body.map { |e| { url: e['url'], file: File.basename(e['path']) } }
                       .select { |m| @file.include?(m[:file]) }
        unless artifacts and !artifacts.empty?
          UI.user_error! "Not Found Artifact download url! 🚀"
        end
        artifacts.each do |artifact|
          download_url = "#{artifact[:url]}?circle-token=#{@token}"
          destination_path = "#{@dist}/#{artifact[:file]}"
          UI.message download_url
          File.delete(destination_path) if File.exist?(destination_path)
          DownloadFileAction.run(
            url: download_url,
            destination_path: destination_path
          )
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################
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
          FastlaneCore::ConfigItem.new(key: :file,
                               description: "artifact file",
                                      type: Array,
                              verify_block: proc do |value|
                                UI.user_error!("No file for Circle CI given") unless value and !value.empty?
                              end),
          FastlaneCore::ConfigItem.new(key: :dist,
                               description: "destination path",
                                      type: String,
                              verify_block: proc do |value|
                                UI.user_error!("No dist for Circle CI given") unless value and !value.empty?
                              end)
        ]
      end

      def self.description
        "Downloads a Circle CI artifact's"
      end

      def self.details
        "This action downloads a Circle CI artifact's using the Circle CI API and puts it in a destination path."
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
