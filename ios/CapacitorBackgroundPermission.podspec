require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorBackgroundPermission'
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
  
  s.post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'CapacitorBackgroundPermission'
        check_info_plist_keys(installer)
      end
    end
  end
end

def check_info_plist_keys(installer)
  required_keys = [
    'NSLocationAlwaysAndWhenInUseUsageDescription',
    'NSLocationWhenInUseUsageDescription',
    'NSLocationAlwaysUsageDescription'
  ]
  
  missing_keys = []
  checked = false
  
  # Try to find and check the main app's Info.plist
  # Check common Capacitor Info.plist locations relative to the project root
  project_root = File.expand_path(File.join(installer.sandbox.root, '..', '..'))
  common_paths = [
    File.join(project_root, 'ios', 'App', 'App', 'Info.plist'),
    File.join(project_root, 'ios', 'App', 'Info.plist'),
    File.join(project_root, 'App', 'App', 'Info.plist'),
    File.join(project_root, 'App', 'Info.plist')
  ]
  
  common_paths.each do |path|
    if File.exist?(path)
      checked = true
      begin
        plist_content = File.read(path)
        required_keys.each do |key|
          unless plist_content.include?(key)
            missing_keys << key unless missing_keys.include?(key)
          end
        end
      rescue => e
        # If we can't read the file, just warn about it
        puts "\n⚠️  [CapacitorBackgroundPermission] Could not read Info.plist at #{path}"
      end
      break
    end
  end
  
  if checked && missing_keys.any?
    puts "\n⚠️  [CapacitorBackgroundPermission] WARNING: Missing required Info.plist keys:"
    missing_keys.each do |key|
      puts "   - #{key}"
    end
    puts "\n   Please add these keys to your app's Info.plist file."
    puts "   See README.md for instructions or run:"
    puts "   ruby ios/Plugin/add_info_plist_keys.rb\n"
  elsif checked
    puts "\n✅ [CapacitorBackgroundPermission] All required Info.plist keys are present.\n"
  else
    puts "\n⚠️  [CapacitorBackgroundPermission] INFO: Could not locate Info.plist to verify keys."
    puts "   Please ensure the following keys are added to your Info.plist:"
    required_keys.each do |key|
      puts "   - #{key}"
    end
    puts "   Run: ruby ios/Plugin/add_info_plist_keys.rb\n"
  end
end

