platform:ios,'13.0'
inhibit_all_warnings!
use_modular_headers!


def pods
    pod 'SnapKit'
    pod 'Material'
    pod 'KVOController'
    pod 'SVProgressHUD'
    pod 'FDFullscreenPopGesture'
    pod 'Moya/RxSwift'
    pod 'ObjectMapper'
    pod 'SwiftyJSON'
    pod 'DeviceKit'
    pod 'DefaultsKit', :git => 'https://github.com/nmdias/DefaultsKit'
    pod 'IceCream'
    
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxGesture'
    pod 'RxDataSources'
    pod 'NSObject+Rx'
    
    pod 'MJRefresh'
    pod 'Kingfisher'
    pod 'MercariQRScanner', :git => 'https://github.com/Finb/QRScanner'
end

target 'Bark' do
    pods
    
    target 'BarkTests' do
      inherit! :search_paths
    end
    
end


target 'NotificationServiceExtension' do
    pod 'IceCream'
    pod 'Kingfisher'
end
