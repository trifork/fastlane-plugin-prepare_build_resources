module Fastlane
  module Actions
    class PrepareBuildResourcesAction < Action
      def self.run(params)
        @debug_messages = []
        @dry_run = params[:dry_run]
        @verbose = params[:verbose] || @dry_run

        keychain_path = self.validate_keychain(params)
        profile_paths = self.validate_profiles(params)

        safe_keychain_path = self.safe_keychain_path(keychain_path)
        safe_profile_paths = self.safe_profile_paths(profile_paths)

        known_keychains = self.known_keychains
        prepared_keychains = self.prepare_keychains(known_keychains, safe_keychain_path)

        safe_profile_paths.each do |dest, src|
          self.cp(src, dest)
        end

        self.cp(keychain_path, safe_keychain_path)

        self.execute(
          "security list-keychains -s #{prepared_keychains.shelljoin}",
          proc { |_| self.safe_cleanup_resource(safe_keychain_path, safe_profile_paths, known_keychains) }
        )

        self.execute(
          "security unlock-keychain -p #{params[:keychain_password].shellescape} #{safe_keychain_path.shellescape}",
          proc { |_| self.safe_cleanup_resource(safe_keychain_path, safe_profile_paths, known_keychains) }
        )

        begin
          Dir.chdir('fastlane') do
            params[:build].call(safe_keychain_path, safe_profile_paths) unless @dry_run
          end
        rescue
          raise
        ensure
          self.safe_cleanup_resource(safe_keychain_path, safe_profile_paths, known_keychains)
        end

        return @debug_messages.join("\n") if Helper.is_test?
      end

      # internal methods:

      def self.safe_cleanup_resource(safe_keychain_path, safe_profile_paths, known_keychains)
        self.execute(
          "security lock-keychain #{safe_keychain_path.shellescape}",
          lambda do |_|
            self.reset_keychain(known_keychains, safe_keychain_path, safe_profile_paths)
            self.cleanup_files(safe_keychain_path, safe_profile_paths)
          end
        )

        self.reset_keychain(known_keychains, safe_keychain_path, safe_profile_paths)

        self.cleanup_files(safe_keychain_path, safe_profile_paths)
      end

      def self.reset_keychain(known_keychains, safe_keychain_path, safe_profile_paths)
        self.execute(
          "security list-keychains -s #{known_keychains.shelljoin}",
          proc { |_| self.cleanup_files(safe_keychain_path, safe_profile_paths) }
        )
      end

      def self.cleanup_files(safe_keychain_path, safe_profile_paths)
        begin
          safe_profile_paths.each do |file, _|
            self.rm(file)
          end
        rescue
        end

        begin
          self.rm(safe_keychain_path)
        rescue
        end
      end

      def self.validate_keychain(params)
        keychain_path = File.expand_path params[:keychain_path]
        UI.user_error! "Keychain '#{params[:keychain_path]}' was not found." unless File.exist?(keychain_path)

        keychain_path
      end

      def self.validate_profiles(params)
        UI.user_error! "No provisioning profiles were provided." unless params[:provisioning_profile_paths].length > 0
        profiles = []
        params[:provisioning_profile_paths].each do |p|
          path = File.expand_path p
          UI.user_error! "Provisioning profile '#{p}' was not found." unless File.exist?(path)
          profiles.push(path)
        end

        profiles
      end

      def self.safe_keychain_path(keychain_path)
        random_name = self.random_name(16)
        safe_keychain_path = File.join(File.dirname(keychain_path), "#{random_name}.keychain")

        safe_keychain_path
      end

      def self.random_name(length)
        random_name = rand(36**length).to_s(36)

        random_name
      end

      def self.safe_profile_paths(profile_paths)
        safe_profiles = {}
        profile_paths.each do |path|
          safe_path = nil
          loop do
            random_name = self.random_name(32)
            safe_path = File.expand_path(File.join("~/Library/MobileDevice/Provisioning Profiles/", "prepare-build-resources-#{random_name}.mobileprovision"))
            break unless safe_profiles.key?(safe_path)
          end
          safe_profiles[safe_path] = path
        end

        safe_profiles
      end

      def self.known_keychains
        keychains = []
        output = Fastlane::Actions.sh("security list-keychains", log: false).split(/\n/)
        output.each do |k|
          next if k.include?("/System.keychain")
          trimmed_keychain = k.strip
          keychains.push(trimmed_keychain[1..-2])
        end

        keychains
      end

      def self.prepare_keychains(known_keychains, safe_keychain_path)
        prepared_keychains = known_keychains.dup
        prepared_keychains.unshift(safe_keychain_path)

        prepared_keychains
      end

      def self.execute(command, error_callback = nil)
        @debug_messages.push("$ #{command}")
        output = ""
        if @dry_run
          UI.message @debug_messages.last if @verbose
        else
          output = Fastlane::Actions.sh(command, log: @verbose, error_callback: error_callback)
        end

        output
      end

      def self.cp(src, dest)
        @debug_messages.push("$ cp #{src} -> #{dest}")
        UI.message @debug_messages.last if @verbose
        FileUtils.cp(src, dest) unless @dry_run
      end

      def self.rm(file)
        @debug_messages.push("$ rm #{file}")
        UI.message @debug_messages.last if @verbose
        File.delete(file) unless @dry_run || !File.exist?(file)
      end

      # Fastlane methods:

      def self.description
        "Prepares certificates and provisioning profiles for building and removes them afterwards."
      end

      def self.authors
        ["Jakob Jensen"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :build,
                                  env_name: "PREPARE_BUILD_RESOURCES_BUILD",
                               description: "A block with the actual building that should be performed",
                                  optional: false,
                                      type: Proc),
          FastlaneCore::ConfigItem.new(key: :keychain_path,
                                  env_name: "PREPARE_BUILD_RESOURCES_KEYCHAIN_PATH",
                               description: "Path to the keychain that need to be available while building",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :keychain_password,
                                  env_name: "PREPARE_BUILD_RESOURCES_KEYCHAIN_PASSWORD",
                               description: "Password to the supplied keychain",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :provisioning_profile_paths,
                                  env_name: "PREPARE_BUILD_RESOURCES_YOUR_PROVISIONING_PROFILE_PATHS",
                               description: "Paths to the provisioning profiles that need to be available while building",
                                  optional: false,
                                      type: Array),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                  env_name: "PREPARE_BUILD_RESOURCES_YOUR_VERBOSE",
                               description: "Print verbose information about what the plugin is doing, *NOTE* that this will print your keychain password as well",
                             default_value: false,
                                  optional: true,
                                      type: TrueClass),
          FastlaneCore::ConfigItem.new(key: :dry_run,
                                  env_name: "PREPARE_BUILD_RESOURCES_YOUR_DRY_RUN",
                               description: "Do not perform changes, but instead print what would have happened",
                             default_value: false,
                                  optional: true,
                                      type: TrueClass)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
