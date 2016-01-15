Pod::Spec.new do |s|

  s.name         = "Hydra"
  s.version      = "1.2.0"
  s.summary      = "Hydra is a framework designed to make developing mobile apps easier."
  s.homepage     = "https://github.com/P9SOFT/Hydra"
  s.license      = { :type => 'MIT' }
  s.author       = { "Tae Hyun Na" => "taehyun.na@gmail.com" }

  s.ios.deployment_target = '6.0'
  s.requires_arc = true

  s.source       = { :git => "https://github.com/P9SOFT/Hydra.git", :tag => "1.2.0" }
  s.source_files  = "Hydra/Hydra/*.{h,m}"
  s.public_header_files = "Hydra/Hydra/*.h"

end
