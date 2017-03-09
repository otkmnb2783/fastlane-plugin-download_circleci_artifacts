require 'circleci'

module Fastlane
  module Helper
    class DownloadCircleciArtifactsHelper
      def self.token(params)
        token = params[:api_token].nil? ? ENV['CIRCLECI_TOKEN'] : params[:api_token]
        CircleCi.configure do |config|
          config.token = token
        end
        token
      end

      def self.user_name(params)
        params[:user_name].nil? ? ENV['CIRCLECI_USER_NAME'] : params[:user_name]
      end

      def self.repository(params)
        params[:repository].nil? ? ENV['CIRCLECI_REPOSITORY'] : params[:repository]
      end

      def self.recent_build_count(params)
        count = params[:repository].nil? ? ENV['CIRCLECI_RECENT_BUILD_COUNT'] : params[:recent_build_count]
        count.nil? ? 10 : count.to_i
      end

      def self.convert_to(response)
        rows = []
        response.each_with_index do |build, index|
          time = distance_of_months Time.parse(build[:finish_time])
          rows << [index + 1, build[:num], time, build[:branch], build[:subject], build[:committer]]
        end
        rows << [0, "cancel", "", "", "No selection, exit fastlane!", ""]
        table = Terminal::Table.new(
          title: 'Circle CI',
          headings: ['Number', 'Build Number', 'Build Finish Time', 'Branch', 'Subject', 'Committer'],
          rows: rows
        )
        table
      end

      def self.show(response)
        table = convert_to(response)
        UI.message 'Please select the line number of the artifact you want to download.'
        puts table
        i = UI.input "line number?"
        i = i.to_i - 1
        if i >= 0 && response[i]
          selection = response[i][:num]
          UI.important "Build Number `#{selection}."
          return selection
        else
          UI.user_error! "cancel 🚀"
        end
      end

      def self.distance_of_months(from_time, to_time = Time.now)
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        from_time, to_time = to_time, from_time if from_time > to_time
        distance_in_minutes = ((to_time - from_time) / 60.0).round
        case distance_in_minutes
        when 0...60 then format("%d minutes ago", distance_in_minutes)
        when 61...1440 then format("%d hr ago", (distance_in_minutes.to_f / 60.0).round)
        else format("%d days ago(#{from_time.to_time})", (distance_in_minutes.to_f / 1440.0).round)
        end
      end
    end
  end
end
