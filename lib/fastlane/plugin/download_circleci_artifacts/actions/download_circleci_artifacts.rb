module Fastlane
  module Actions
    class DownloadCircleciArtifactsAction < Action
      def self.run(params)
        require 'circleci'
        require 'open-uri'
        require 'fileutils'
        Actions.verify_gem!('circleci')
        configure(params)
        artifacts = get(params)
        artifacts.each do |artifact|
          destination_path = "#{@dist}/#{artifact[:file]}"
          File.delete(destination_path) if File.exist?(destination_path)
          download_artifact(artifact[:url].to_s, destination_path)
        end
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
        artifacts
      end

      def self.download_artifact(artifact_url, destination_path)
        UI.important "Download artifact url #{artifact_url}"
        request_url = "#{artifact_url}?circle-token=#{@token}"
        send_download_request(request_url, "fastlane-plugin_download_circleci_artifacts", "application/octet-stream", destination_path)
        puts "finish"
        compressed_file_size = File.size(destination_path).to_f / 2**20
        formatted_file_size = format('%.2f', compressed_file_size)
        UI.success("Download finished, total size: #{formatted_file_size} MB ✅")
      rescue => ex
        UI.user_error!("Error fetching release's artifact: #{ex}")
      end

      def self.send_download_request(request_url, user_agent, accept, destination_path)
        step = 0
        partial = 0
        progress = 0
        File.open(destination_path, "wb") do |saved_file|
          # the following "open" is provided by open-uri
          open(request_url, "User-Agent" => user_agent, "Accept" => accept, :content_length_proc => lambda do |t|
            if t && 0 < t
              step = t / 10
              partial = step
              formatted_file_size = format('%.2f', t.to_f / 2**20)
              UI.important("Total size: #{formatted_file_size} MB")
            else
              partial = 5 * 1024 * 1024
            end
          end,
          :progress_proc => lambda do |s|
            if s > partial
              if step.zero?
                puts '.'
                partial += (5 * 1024 * 1024)
                formatted_file_size = format('%.1f', s.to_f / 2**20)
                UI.message("download size: #{formatted_file_size} MB")
              else
                partial += step
                UI.message "#{progress}%"
                progress = (partial / step) * 10
              end
            else
              if step.zero?
                print '.'
              end
            end
          end) do |read_file|
            saved_file.write(read_file.read)
          end
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
