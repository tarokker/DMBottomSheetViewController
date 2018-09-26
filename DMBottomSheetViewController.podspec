#
#  Be sure to run `pod spec lint DGActivityIndicatorView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "DMBottomSheetViewController"
  s.version      = "1.0.12"
  s.authors      = { "Daniele Maiorana" => "tarokker@gmail.com" }
  s.homepage     = "https://github.com/tarokker/DMBottomSheetViewController"
  s.summary      = "DMBottomSheetViewController."
  s.source       = { :git => "https://github.com/tarokker/DMBottomSheetViewController.git",
                     :tag => '1.0.12' }
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.platform = :ios, '7.0'
  s.source_files = "TestBottomSheet/DMBottomSheetViewController.{h,m}"

  s.requires_arc = true

  s.resources = ["TestBottomSheet/*.png"]
  s.ios.deployment_target = '7.0'
  s.ios.frameworks = ['UIKit', 'Foundation']
end
