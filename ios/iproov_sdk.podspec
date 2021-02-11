Pod::Spec.new do |s|
  s.name             = 'iproov_sdk'
  s.version          = '8.1.1'
  s.summary          = 'Flexible authentication for identity assurance'
  s.homepage         = 'https://www.iproov.com/'
  s.license          = { :type => 'commercial', :file => '../LICENSE.md' }
  s.author           = { 'iProov' => 'support@iproov.com' }
  s.source           = { :git => 'https://github.com/iProov/ios.git', :tag => s.version.to_s }
  
  s.source_files = 'Classes/**/*'
  
  s.dependency 'Flutter'
  s.dependency 'iProov'
  
  s.swift_version = '5.3'
  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
