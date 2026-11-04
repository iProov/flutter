require "yaml"

pubspec = YAML.load_file('../pubspec.yaml')

Pod::Spec.new do |s|
  s.name             = pubspec["name"]
  s.version          = pubspec["version"]
  s.summary          = pubspec["description"]
  s.homepage         = pubspec["homepage"]
  s.license          = { :type => 'commercial', :file => '../LICENSE.md' }
  s.author           = { 'iProov' => 'support@iproov.com' }
  s.source           = { :path => '.' }
  
  s.source_files = 'iproov_flutter/Sources/iproov_flutter/**/*.swift'
  
  s.dependency 'Flutter'
  s.vendored_frameworks = 'iproov_flutter/Frameworks/iProov.xcframework'
  
  s.swift_version = '5.0'
  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
