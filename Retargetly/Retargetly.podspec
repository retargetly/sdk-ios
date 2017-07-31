Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "Retargetly"
s.summary = "Retargetly is a tracking library for iOS"
s.requires_arc = true


# 2
s.version = "0.1.0"


# 3
s.license = { :type => "MIT", :file => "LICENSE" }


# 4
s.author = { "José Valderrama" => "josevalderrama18@gmail.com" }


# 5
s.homepage = "http://nextdots.com/"


# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "git@bitbucket.org:nextdotsjolivieri/retargetly-ios.git", :tag => "#{s.version}"}


# 7
s.dependency 'Alamofire', '~> 4.4'


# 8
s.source_files = "Retargetly/**/*.{swift}"


# 9
s.resources = "Retargetly/**/*.{png,jpeg,jpg,storyboard,xib}"
end
