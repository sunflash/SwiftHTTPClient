# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
use_frameworks!

abstract_target 'SwiftHttpClient' do

    pod 'KeychainSwift'
    pod 'RealmSwift'
    pod 'SwiftLint'

    target 'HTTPClient' do

    end

    target 'HTTPClientTests' do
        pod 'AEXML'
        pod 'Kanna'
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
