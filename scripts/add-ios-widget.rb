# Adds the SehariWidget WidgetKit extension to ios/App/App.xcodeproj and embeds it in the app.
# Safe to run more than once. Needs: gem install xcodeproj
require 'xcodeproj'

ROOT = File.expand_path('../ios/App', __dir__)
project = Xcodeproj::Project.open(File.join(ROOT, 'App.xcodeproj'))
app = project.targets.find { |t| t.name == 'App' } or abort 'App target not found'
TEAM = app.build_configurations.first.build_settings['DEVELOPMENT_TEAM']

# The app itself needs the App Group entitlement to share data with the widget.
app.build_configurations.each { |c| c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements' }
app_group = project.main_group.find_subpath('App', false)
app_group.new_file('App.entitlements') unless app_group.files.any? { |f| f.path == 'App.entitlements' }

if project.targets.any? { |t| t.name == 'SehariWidget' }
  project.save
  puts 'SehariWidget target already present; app entitlements checked.'
  exit
end

widget = project.new_target(:app_extension, 'SehariWidget', :ios, '16.0', nil, :swift)
widget.product_reference.name = 'SehariWidget.appex'

group = project.main_group.new_group('SehariWidget', 'SehariWidget')
widget.add_file_references([group.new_file('SehariWidget.swift')])
widget.add_resources([group.new_file('Assets.xcassets'), group.new_file('DMSerifDisplay-Regular.ttf')])
group.new_file('Info.plist')
group.new_file('SehariWidget.entitlements')

%w[WidgetKit SwiftUI].each do |fw|
  ref = project.frameworks_group.files.find { |f| f.path == "System/Library/Frameworks/#{fw}.framework" } ||
        project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework", :sdk_root)
  widget.frameworks_build_phase.add_file_reference(ref, true)
end

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'my.sehariselembar.app.SehariWidget'
  s['INFOPLIST_FILE'] = 'SehariWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'SehariWidget/SehariWidget.entitlements'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = TEAM if TEAM
  s['MARKETING_VERSION'] = '1.0'
  s['CURRENT_PROJECT_VERSION'] = '1'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
end

# Build the widget with the app and copy it into App.app/PlugIns.
app.add_dependency(widget)
embed = app.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' } || app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference, true).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Turn on the App Groups capability for both targets.
attrs = project.root_object.attributes['TargetAttributes'] ||= {}
[app, widget].each do |t|
  a = attrs[t.uuid] ||= {}
  a['SystemCapabilities'] = { 'com.apple.ApplicationGroups.iOS' => { 'enabled' => 1 } }
end

project.save
puts 'Added SehariWidget extension target and embedded it in App.'
