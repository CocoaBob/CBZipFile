Pod::Spec.new do |s|
  s.name         = "CBZipFile"
  s.version      = "1.1.0"
  s.summary      = "A Cocoa wrapper of minizip to read zip packages"
  s.description  = <<-DESC
                   CBZipFile is a Cocoa wrapper of minizip to read zip packages, it's thread-safe and particularly optimised for random accessing.
                   DESC
  s.homepage     = "https://github.com/CocoaBob/CBZipFile"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author    = "CocoaBob"
  s.social_media_url = 'https://twitter.com/CocoaBob'
  s.platform     = :ios, "5.0"
  s.source       = { :git => "https://github.com/CocoaBob/CBZipFile.git", :tag => "1.1.0" }
  s.source_files  = "*.{h,m}", "minizip/*.{h,c}"
  s.requires_arc = true
  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) NOUNCRYPT" }
  s.library   = 'z'
end