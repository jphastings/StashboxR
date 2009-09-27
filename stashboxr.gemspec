spec = Gem::Specification.new do |s| 
  s.name = "stashboxr"
  s.version = "0.4.0"
  s.author = "JP Hastings-Spital"
  s.email = "stashboxr@projects.kedakai.co.uk"
  s.homepage = "http://projects.kedakai.co.uk/stashboxr/"
  s.platform = Gem::Platform::RUBY
  s.description = "A ruby interface to the file host Stashbox.org"
  s.summary = "A ruby interface to the file host Stashbox.org"
  s.files = ["stashboxr.rb"]
  s.require_paths = ["."]
  s.add_dependency("libxml-ruby")
  s.has_rdoc = true
end
