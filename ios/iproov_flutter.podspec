require "yaml"

pubspec = YAML.load_file('../pubspec.yaml')

Pod::Spec.new do |s|
  s.name             = pubspec["name"]
  s.version          = pubspec["version"]
  s.summary          = pubspec["description"]
  s.homepage         = pubspec["homepage"]
  s.license          = { :type => 'commercial', :file => '../LICENSE.md' }
  s.author           = { 'iProov' => 'support@iproov.com' }
  s.source           = { :git => 'https://github.com/iProov/ios.git', :tag => s.version.to_s }
  
  s.source_files = 'Classes/**/*'
  
  s.dependency 'Flutter'
  s.dependency 'iProov', '13.0.0'
  
  s.swift_version = '5.5'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
