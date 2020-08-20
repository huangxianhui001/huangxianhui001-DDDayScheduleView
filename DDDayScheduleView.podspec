#
# Be sure to run `pod lib lint DDDayScheduleView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DDDayScheduleView'
  s.version          = '0.1.0'
  s.summary          = '仿钉钉日历页面内,日模式的一天工作计划安排页面'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/huangxianhui001/huangxianhui001-DDDayScheduleView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '756673457@qq.com' => '756673457@qq.com' }
  s.source           = { :git => 'https://github.com/huangxianhui001/huangxianhui001-DDDayScheduleView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'DDDayScheduleView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DDDayScheduleView' => ['DDDayScheduleView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'SnapKit'
end
