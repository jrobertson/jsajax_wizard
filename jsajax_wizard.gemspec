Gem::Specification.new do |s|
  s.name = 'jsajax_wizard'
  s.version = '0.1.0'
  s.summary = 'Makes building an AJAX web page easier than copying and pasting an example. '
  s.authors = ['James Robertson']
  s.files = Dir['lib/jsajax_wizard.rb']
  s.add_runtime_dependency('rexle', '~> 1.5', '>=1.5.2')  
  s.signing_key = '../privatekeys/jsajax_wizard.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/jsajax_wizard'
end
