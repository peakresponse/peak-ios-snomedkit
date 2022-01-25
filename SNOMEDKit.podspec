#
# Be sure to run `pod lib lint SNOMEDKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SNOMEDKit'
  s.version          = '0.1.0'
  s.summary          = 'SNOMEDKit is a library for embedding SNOMED codes as a Realm database.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SNOMEDKit is a library for embedding SNOMED codes as a Realm database. The example
  application included with the library can be run on a Mac OS desktop to read SNOMED
  code files and generate a compacted Realm database that can be bundled into an iOS app.
                       DESC

  s.homepage         = 'https://github.com/peakresponse/peak-ios-snomedkit'
  s.license          = { :type => 'LGPL', :file => 'LICENSE.md' }
  s.author           = { 'Francis Li' => 'francis@peakresponse.net' }
  s.source           = { :git => 'https://github.com/peakresponse/peak-ios-snomedkit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.4'
  s.swift_versions = ['4.0', '4.2', '5.0']

  s.source_files = 'SNOMEDKit/Classes/**/*'
  s.dependency 'RealmSwift', '>=10.11.0'
end
