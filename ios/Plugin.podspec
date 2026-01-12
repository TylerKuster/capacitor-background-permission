require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'BackgroundLocationPermission'
  s.version = package['version']
  s.summary = 'Capacitor plugin for background location permissions'
  s.license = 'MIT'
  s.homepage = 'https://github.com/TylerKuster/capacitor-background-permission'
  s.author = package['author']
  s.source = { :git => 'https://github.com/TylerKuster/capacitor-background-permission.git' }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '13.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
end

