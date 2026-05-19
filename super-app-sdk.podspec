require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'super-app-sdk'
  s.version      = package['version']
  s.summary      = package['description']
  s.description  = package['description']
  s.homepage     = package['homepage'] || 'https://example.com/super-app-sdk'
  s.license      = package['license'] || 'UNLICENSED'
  s.authors      = { (package['author'] || 'TNG') => 'noreply@example.com' }

  s.platforms    = { :ios => '13.0' }
  s.source       = { :git => 'https://example.com/super-app-sdk.git', :tag => "v#{s.version}" }

  s.source_files = 'ios/**/*.{h,m,mm}'
  s.requires_arc = true

  s.dependency 'React-Core'
end
