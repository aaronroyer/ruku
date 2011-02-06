Gem::Specification.new do |s|
  s.name = 'ruku'
  s.version = '0.2'
  s.date = '2011-2-1'
  s.platform = Gem::Platform::RUBY

  s.description = 'Roku™ set-top box remote control, command line and web interfaces'
  s.summary = 'Ruku provides command line and web remote control interfaces for ' +
              'controlling all your Roku™ set-top boxes over a network.'

  s.authors     = ['Aaron Royer']
  s.email       = 'aaronroyer@gmail.com'

  s.files       = Dir['{bin/*,lib/**/*,test/**/*}'] +
                  %w[README.rdoc MIT-LICENSE ruku.gemspec Rakefile]

  s.executables << 'ruku'

  s.test_files = s.files.select {|path| path =~ /^test\/test_.*\.rb/}

  s.has_rdoc = true
  s.extra_rdoc_files = ['MIT-LICENSE']
  s.homepage = 'http://github.com/aaronroyer/ruku'
  s.rdoc_options = ["--line-numbers", "--inline-source"]
  s.require_paths = ['lib']


  s.add_runtime_dependency('json_pure', ['>= 1.4.6'])

  s.add_development_dependency('mocha', ['>= 0.9.9'])
end
