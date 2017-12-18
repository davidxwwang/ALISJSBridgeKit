#
# Be sure to run `pod lib lint ALISJSBridgeKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ALISJSBridgeKit'
  s.version          = '0.1.1'
  s.summary          = '阿里体育JavaScriptBridge'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/davidxwwang/ALISJSBridgeKit.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xwwang_0102@qq.com' => 'xingwang.wxw@alibaba-inc.com' }
  s.source           = { :git => 'https://github.com/davidxwwang/ALISJSBridgeKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.subspec 'ALSJSBridgeBase' do |cs|
    cs.source_files  = 'ALISJSBridgeKit/Classes/ALSJSBridgeBase/**/*'
  end

  s.subspec 'ALSJSBridge' do |cs|
    cs.source_files  = 'ALISJSBridgeKit/Classes/ALSJSBridge/**/*'
    cs.dependency 'ALISJSBridgeKit/ALSJSBridgeBase'
  end
  
  s.subspec 'ALSJSBridgePlugins' do |cs|
    cs.source_files  = 'ALISJSBridgeKit/Classes/ALSJSBridgePlugins/**/*'
    cs.dependency 'ALISJSBridgeKit/ALSJSBridgeBase'
    
#cs.dependency 'NebulaSDK'
#    cs.dependency 'APOpenSSL'
    cs.dependency 'AEHybridEngine'
  end
 
end
