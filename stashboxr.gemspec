# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{stashboxr}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["JP Hastings-Spital"]
  s.date = %q{2010-06-09}
  s.description = %q{Upload files to stashbox.org and manage their metadata. User accounts or anonymous uploads!}
  s.email = %q{jphastings@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/stashboxr.rb",
     "stashboxr.gemspec"
  ]
  s.homepage = %q{http://github.com/jphastings/StashboxR}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A ruby api for the stashbox.org website}
  s.test_files = [
    "test/helper.rb",
     "test/test_stashboxr.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mechanize>, [">= 1.0.0"])
      s.add_development_dependency(%q<Shoulda>, [">= 0"])
    else
      s.add_dependency(%q<mechanize>, [">= 1.0.0"])
      s.add_dependency(%q<Shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<mechanize>, [">= 1.0.0"])
    s.add_dependency(%q<Shoulda>, [">= 0"])
  end
end

