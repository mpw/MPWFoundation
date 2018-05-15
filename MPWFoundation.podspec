Pod::Spec.new do |spec|
  spec.name         = 'MPWFoundation'
  spec.version      = '3.0.0'
  spec.license      = { :type => 'BSD' }
  spec.homepage     = 'https://github.com/mpw/MPWFoundation'
  spec.authors      = { 'Marcel Weiher' => 'marcel@metaobject.com' }
  spec.summary      = 'HOM and ObjectStreams.'
  spec.source       = { :git => 'https://github.com/mpw/MPWFoundation.git', :tag => '3.0.0' }
  spec.source_files = 'Classes/MPWObject.{h,m}'
  spec.framework    = 'Foundation'
end
