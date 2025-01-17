source 'https://github.com/CocoaPods/Specs.git'

platform:ios,'13.0'
inhibit_all_warnings!
use_modular_headers!


def pods
    pod 'SnapKit'
    pod 'Material'
    pod 'SVProgressHUD'
    pod 'FDFullscreenPopGesture'
    pod 'Moya/RxSwift'
    pod 'ObjectMapper'
    pod 'SwiftyJSON'
    pod 'DefaultsKit'
    pod 'RealmSwift'
    pod 'CryptoSwift'
    pod 'IQKeyboardManagerSwift/IQKeyboardToolbarManager'
    
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxGesture'
    pod 'RxDataSources'
    pod 'NSObject+Rx'
    
    pod 'MJRefresh'
    pod 'Kingfisher'
    pod 'MercariQRScanner', :git => 'https://github.com/Finb/QRScanner'
    pod 'DropDown'
    
    pod 'SwiftyStoreKit'
end

target 'Bark' do
    pods
    
    target 'BarkTests' do
      inherit! :search_paths
    end
    
end


target 'NotificationServiceExtension' do
    pod 'RealmSwift'
    pod 'Kingfisher'
    pod 'CryptoSwift'
    pod 'SwiftyJSON'
end

target 'NotificationContentExtension' do
    pod 'Kingfisher'
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 13.0
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
    end
end
