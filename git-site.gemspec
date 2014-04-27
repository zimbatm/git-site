Gem::Specification.new do |s|
  s.name = "git-site"
  s.version = '0.1.0'
  s.homepage = 'https://github.com/zimbatm/git-site'
  s.summary = 'Service git content statically'
  s.description = 'Micro webserver that serves git data directly from the repo.'
  s.license = 'MIT'
  s.author = 'zimbatm'
  s.email = 'zimbatm@zimbatm.com'
  s.files = ['README.md', 'bin/git-site', 'lib/git-site.rb']
  s.executable = 'git-site'

  s.add_dependency 'gitlab-grack', '2.0.0.pre'
  s.add_dependency 'mimemagic'
  s.add_dependency 'rack'
  s.add_dependency 'rugged'
end
