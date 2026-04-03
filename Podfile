# Podfile for SpellFlare iOS App

platform :ios, '16.0'

# Inhibit all warnings from CocoaPods libraries
inhibit_all_warnings!

target 'spelling-bee iOS App' do
  # Use frameworks
  use_frameworks!

  # Google Mobile Ads SDK (includes UserMessagingPlatform)
  pod 'Google-Mobile-Ads-SDK', '~> 11.0'

  # AppLovin mediation adapter for AdMob
  # NOTE: Do NOT initialize AppLovin manually - AdMob handles this automatically
  pod 'GoogleMobileAdsMediationAppLovin'

  # Firebase
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseFunctions'
  pod 'FirebaseMessaging'
  pod 'FirebaseAnalytics'

  # Post-install hook to fix compatibility issues
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # Set minimum deployment target
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'

        # Fix code signing
        config.build_settings['CODE_SIGN_IDENTITY'] = ''
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'

        # Disable bitcode (deprecated in Xcode 14+)
        config.build_settings['ENABLE_BITCODE'] = 'NO'

        # Fix User Script Sandboxing for resource copying
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end

    # Fix the resources script to use a temp directory instead of Pods/
    resources_script = File.join(installer.sandbox.root, 'Target Support Files', 'Pods-spelling-bee iOS App', 'Pods-spelling-bee iOS App-resources.sh')
    if File.exist?(resources_script)
      text = File.read(resources_script)
      # Change the resources file to use TEMP_DIR instead of PODS_ROOT
      new_text = text.gsub(
        'RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt',
        'RESOURCES_TO_COPY="${TEMP_DIR}/resources-to-copy-${TARGETNAME}.txt"'
      )
      # Fix realpath -m to use perl instead (macOS doesn't support -m)
      new_text = new_text.gsub(
        /realpath -m/,
        'perl -MCwd -e "print Cwd::abs_path shift"'
      )
      File.write(resources_script, new_text)
      puts "✅ Fixed resources script for macOS compatibility"
    end
  end
end
