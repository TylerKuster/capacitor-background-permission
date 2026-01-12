#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to automatically add required Info.plist keys for BackgroundLocationPermission plugin
# Usage: ruby ios/Plugin/add_info_plist_keys.rb [path_to_Info.plist] [description]

require 'rexml/document'
require 'fileutils'

# Default description
DEFAULT_DESCRIPTION = 'This app requires background location access to provide geofencing features.'

# Required keys
REQUIRED_KEYS = {
  'NSLocationAlwaysAndWhenInUseUsageDescription' => DEFAULT_DESCRIPTION,
  'NSLocationWhenInUseUsageDescription' => DEFAULT_DESCRIPTION,
  'NSLocationAlwaysUsageDescription' => DEFAULT_DESCRIPTION
}.freeze

def find_info_plist(start_dir = Dir.pwd)
  # Common Capacitor Info.plist locations
  search_paths = [
    File.join(start_dir, 'ios', 'App', 'App', 'Info.plist'),
    File.join(start_dir, 'ios', 'App', 'Info.plist'),
    File.join(start_dir, 'App', 'App', 'Info.plist'),
    File.join(start_dir, 'App', 'Info.plist'),
    File.join(start_dir, 'Info.plist')
  ]
  
  search_paths.each do |path|
    return path if File.exist?(path)
  end
  
  # Try to find it recursively
  Dir.glob(File.join(start_dir, '**', 'Info.plist')).each do |path|
    # Skip Pods and build directories
    next if path.include?('Pods') || path.include?('build') || path.include?('.xcodeproj')
    return path
  end
  
  nil
end

def add_keys_to_plist(plist_path, description = DEFAULT_DESCRIPTION)
  unless File.exist?(plist_path)
    puts "❌ Error: Info.plist not found at #{plist_path}"
    return false
  end
  
  begin
    # Read existing plist content
    plist_content = File.read(plist_path)
    
    # Parse XML
    doc = REXML::Document.new(plist_content)
    root = doc.root
    
    # Find the dict element (plist root contains a dict)
    dict = root.elements['dict']
    unless dict
      puts "❌ Error: Invalid Info.plist format - no dict element found"
      return false
    end
    
    updated = false
    added_keys = []
    existing_keys = []
    
    # Check existing keys and add missing ones
    REQUIRED_KEYS.each do |key, _|
      # Check if key exists
      key_exists = false
      dict.elements.each('key') do |key_elem|
        if key_elem.text == key
          key_exists = true
          existing_keys << key
          puts "  ✓ #{key} already exists"
          break
        end
      end
      
      unless key_exists
        # Add the key-value pair
        dict.add_element('key').text = key
        string_elem = dict.add_element('string')
        string_elem.text = description
        added_keys << key
        updated = true
        puts "  + Added #{key}"
      end
    end
    
    if updated
      # Write back to plist with proper formatting
      formatter = REXML::Formatters::Pretty.new(2)
      formatter.compact = true
      output = ''
      formatter.write(doc, output)
      
      # Ensure XML declaration is present
      unless output.start_with?('<?xml')
        output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n#{output}"
      end
      
      File.write(plist_path, output)
      puts "\n✅ Successfully updated #{plist_path}"
      puts "   Added #{added_keys.length} key(s)"
      puts "   #{existing_keys.length} key(s) already existed"
      return true
    else
      puts "\n✅ All required keys already exist in #{plist_path}"
      return true
    end
    
  rescue => e
    puts "❌ Error processing Info.plist: #{e.message}"
    puts "   Make sure the file is a valid XML plist"
    puts "   Stack trace: #{e.backtrace.first(3).join("\n   ")}"
    return false
  end
end

def main
  # Parse arguments
  plist_path = ARGV[0]
  description = ARGV[1] || DEFAULT_DESCRIPTION
  
  # Find Info.plist if not provided
  unless plist_path
    puts "🔍 Searching for Info.plist..."
    plist_path = find_info_plist
    
    unless plist_path
      puts "❌ Error: Could not find Info.plist file"
      puts "\nUsage: ruby ios/Plugin/add_info_plist_keys.rb [path_to_Info.plist] [description]"
      puts "\nOr run from your project root and the script will try to find it automatically."
      exit 1
    end
  end
  
  puts "📝 Found Info.plist at: #{plist_path}"
  puts "📋 Using description: #{description}"
  puts "\nAdding required keys:\n"
  
  success = add_keys_to_plist(plist_path, description)
  
  if success
    puts "\n✨ Done! Your Info.plist now includes all required location permission keys."
    puts "   You may want to customize the descriptions to match your app's use case."
    exit 0
  else
    exit 1
  end
end

# Run the script
main if __FILE__ == $PROGRAM_NAME

