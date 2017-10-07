


# Uncomment the next line to define a global platform for your project
platform :ios, '8.0'
use_frameworks!

abstract_target 'SwiftHttpClient' do

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
            if ['AEXML', 'Kanna'].include? target.name
                config.build_settings['SWIFT_VERSION'] = '3.2'
            else
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end

