describe Fastlane::Actions::PrepareBuildResourcesAction do
  describe '#run' do
    it "should with dry run set correctly describe its intentions" do
      keychain_path = '/tmp/my.keychain'
      profile_path = '/tmp/my.mobileprovision'

      FileUtils.touch keychain_path
      FileUtils.touch profile_path

      runner = Fastlane::FastFile.new.parse("lane :test do
          prepare_build_resources(
            dry_run: true,
            provisioning_profile_paths: ['#{profile_path}'],
            keychain_path: '#{keychain_path}',
            keychain_password: 'mySecretPassword',
            build: proc do |cert, profiles|
              # resources available
            end
          )
      end").runner

      result = runner.execute(:test)

      FileUtils.rm keychain_path
      FileUtils.rm profile_path

      expect(result.scan('$ cp').size).to eq(2)
      expect(result.scan('$ rm').size).to eq(2)
      expect(result.scan('$ security list-keychains -s').size).to eq(2)
      expect(result.scan('$ security unlock-keychain').size).to eq(1)
      expect(result.scan('$ security lock-keychain').size).to eq(1)
      expect(result).to include("$ cp /tmp/my.mobileprovision")
      expect(result).to include("$ cp /tmp/my.keychain")
      expect(result).to include("$ security unlock-keychain -p mySecretPassword /tmp/")
      expect(result).to include("$ security lock-keychain /tmp/")
    end

    it "should with dry run set correctly describe its intentions with multiple provisioning profiles" do
      keychain_path = '/tmp/my.keychain'
      profile_path_1 = '/tmp/my1.mobileprovision'
      profile_path_2 = '/tmp/my2.mobileprovision'
      profile_path_3 = '/tmp/my3.mobileprovision'

      FileUtils.touch keychain_path
      FileUtils.touch profile_path_1
      FileUtils.touch profile_path_2
      FileUtils.touch profile_path_3

      runner = Fastlane::FastFile.new.parse("lane :test do
          prepare_build_resources(
            dry_run: true,
            provisioning_profile_paths: ['#{profile_path_1}', '#{profile_path_2}', '#{profile_path_3}'],
            keychain_path: '#{keychain_path}',
            keychain_password: 'mySecretPassword',
            build: proc do |cert, profiles|
              # resources available
            end
          )
      end").runner

      result = runner.execute(:test)

      FileUtils.rm keychain_path
      FileUtils.rm profile_path_1
      FileUtils.rm profile_path_2
      FileUtils.rm profile_path_3

      expect(result.scan('$ cp').size).to eq(4)
      expect(result.scan('$ rm').size).to eq(4)
      expect(result.scan('$ security list-keychains -s').size).to eq(2)
      expect(result.scan('$ security unlock-keychain').size).to eq(1)
      expect(result.scan('$ security lock-keychain').size).to eq(1)
      expect(result).to include("$ cp /tmp/my1.mobileprovision")
      expect(result).to include("$ cp /tmp/my2.mobileprovision")
      expect(result).to include("$ cp /tmp/my3.mobileprovision")
      expect(result).to include("$ cp /tmp/my.keychain")
      expect(result).to include("$ security unlock-keychain -p mySecretPassword /tmp/")
      expect(result).to include("$ security lock-keychain /tmp/")
    end

    it "should move files around and not fail with shell commands mocked" do
      proof_path = '/tmp/my.proof'
      keychain_path = '/tmp/my.keychain'
      profile_path = '/tmp/my.mobileprovision'

      FileUtils.touch keychain_path
      FileUtils.touch profile_path
      FileUtils.rm proof_path if File.exist? proof_path

      allow(Fastlane::Actions::PrepareBuildResourcesAction).to receive(:known_keychains).and_return([])
      allow(Fastlane::Actions::PrepareBuildResourcesAction).to receive(:execute).and_return(nil)

      runner = Fastlane::FastFile.new.parse("lane :test do
          prepare_build_resources(
            provisioning_profile_paths: ['#{profile_path}'],
            keychain_path: '#{keychain_path}',
            keychain_password: 'mySecretPassword',
            build: proc do |cert, profiles|
              system('touch #{proof_path}')
            end
          )
      end").runner

      result = runner.execute(:test)

      FileUtils.rm keychain_path
      FileUtils.rm profile_path

      expect(File.exist?(proof_path)).to eq(true)

      FileUtils.rm proof_path if File.exist? proof_path

      expect(result.scan('$ cp').size).to eq(2)
      expect(result.scan('$ rm').size).to eq(2)
      expect(result).to include("$ cp /tmp/my.mobileprovision")
    end
  end
end
