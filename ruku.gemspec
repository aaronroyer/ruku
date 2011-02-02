Gem::Specification.new do |s|
  s.name = 'ruku'
  s.version = '0.1'
  s.platform = Gem::Platform::RUBY

  s.description = 'set-top box remote web and command line interface'
  s.summary = ""

  s.authors     = ["Aaron Royer"]
  s.email       = "aaronroyer@gmail.com"

  s.files           = Dir['{bin/*,lib/**/*,test/**/*}'] +
                          %w(README LICENSE ruku.gemspec Rakefile)

  s.executables << 'ruku'

  s.test_files = s.files.select {|path| path =~ /^test\/test_.*\.rb/}

  s.has_rdoc = true
  s.homepage = "http://github.com/aaronroyer/ruku"
  s.rdoc_options = ["--line-numbers", "--inline-source"]
  s.require_paths = %w[lib]
end
