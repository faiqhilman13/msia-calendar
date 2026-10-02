# Adds the SehariWidget WidgetKit extension to ios/App/App.xcodeproj and embeds it in the app.
# Safe to run more than once. Needs: gem install xcodeproj
require 'xcodeproj'

ROOT = File.expand_path('../ios/App', __dir__)
project = Xcodeproj::Project.open(File.join(ROOT, 'App.xcodeproj'))
app = project.targets.find { |t| t.name == 'App' } or abort 'App target not found'

# The app itself needs the App Group entitlement to share data with the widget.
app.build_configurations.each { |c| c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements' }
app_group = project.main_group.find_subpath('App', false)
app_group.new_file('App.entitlements') unless app_group.files.any? { |f| f.path == 'App.entitlements' }

# Both targets use the App Group's UserDefaults, an API that needs a declared reason (1C8F.1) in each
# bundle's PrivacyInfo.xcprivacy. App Store Connect rejects uploads without it.
def add_privacy_manifest(target, group)
  ref = group.files.find { |f| f.path == 'PrivacyInfo.xcprivacy' } || group.new_file('PrivacyInfo.xcprivacy')
  target.add_resources([ref]) unless target.resources_build_phase.files_references.include?(ref)
end
add_privacy_manifest(app, app_group)

# SehariStyles.swift draws the widget in each of the app's styles, with these fonts besides DM Serif Display.
# Info.plist lists the same fonts under UIAppFonts.
STYLE_FONTS = %w[BarlowCondensed-Regular BarlowCondensed-SemiBold BarlowCondensed-Bold BarlowCondensed-ExtraBold
                 BarlowCondensed-Black IBMPlexSansCondensed-Medium IBMPlexSansCondensed-SemiBold
                 IBMPlexMono-Regular].map { |f| "#{f}.ttf" }
def add_style_files(target, group)
  ref = group.files.find { |f| f.path == 'SehariStyles.swift' } || group.new_file('SehariStyles.swift')
  target.add_file_references([ref]) unless target.source_build_phase.files_references.include?(ref)
  fonts = STYLE_FONTS.map { |name| group.files.find { |f| f.path == name } || group.new_file(name) }
  target.add_resources(fonts - target.resources_build_phase.files_references)
end

# Both targets take DEVELOPMENT_TEAM from Signing.xcconfig -> Signing.local.xcconfig (git-ignored),
# so no team ID is written into project.pbxproj. The App target's Debug config keeps debug.xcconfig.
signing = project.main_group.files.find { |f| f.path == 'Signing.xcconfig' } || project.main_group.new_file('Signing.xcconfig')
project.build_configurations.each { |c| c.base_configuration_reference = signing }

if (existing = project.targets.find { |t| t.name == 'SehariWidget' })
  widget_group = project.main_group.find_subpath('SehariWidget', false)
  add_privacy_manifest(existing, widget_group)
  add_style_files(existing, widget_group)
  project.save
  puts 'SehariWidget target already present; entitlements, privacy manifests and style files checked.'
  exit
end

widget = project.new_target(:app_extension, 'SehariWidget', :ios, '16.0', nil, :swift)
widget.product_reference.name = 'SehariWidget.appex'

# new_target links Foundation from a hard-coded SDK path (iPhoneOS<n>.sdk) that breaks on other Xcodes.
# Swift links it implicitly, so drop it along with the "iOS" group it creates.
widget.frameworks_build_phase.files_references.select { |r| r.path.to_s.end_with?('/Foundation.framework') }.each do |ref|
  parent = ref.parent
  ref.remove_from_project
  parent.remove_from_project if parent != project.frameworks_group && parent.children.empty?
end

group = project.main_group.new_group('SehariWidget', 'SehariWidget')
widget.add_file_references([group.new_file('SehariWidget.swift')])
widget.add_resources([group.new_file('Assets.xcassets'), group.new_file('DMSerifDisplay-Regular.ttf')])
add_style_files(widget, group)
add_privacy_manifest(widget, group)
group.new_file('Info.plist')
group.new_file('SehariWidget.entitlements')
xcconfig = group.new_file('SehariWidget.xcconfig')

%w[WidgetKit SwiftUI].each do |fw|
  ref = project.frameworks_group.files.find { |f| f.path == "System/Library/Frameworks/#{fw}.framework" } ||
        project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework", :sdk_root)
  widget.frameworks_build_phase.add_file_reference(ref, true)
end

widget.build_configurations.each do |c|
  # SehariWidget.xcconfig sets IPHONEOS_DEPLOYMENT_TARGET = 16.0. It must stay out of project.pbxproj:
  # `npx cap sync` copies the first deployment target it finds there into CapApp-SPM/Package.swift.
  c.base_configuration_reference = xcconfig
  s = c.build_settings
  s.delete('IPHONEOS_DEPLOYMENT_TARGET')
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'my.sehariselembar.app.SehariWidget'
  s['INFOPLIST_FILE'] = 'SehariWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'SehariWidget/SehariWidget.entitlements'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['CODE_SIGN_STYLE'] = 'Automatic'
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
