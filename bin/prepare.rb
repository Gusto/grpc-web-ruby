# frozen_string_literal: true

def set_version
  new_version = ARGV[0]

  contents = File.read('lib/grpc_web/version.rb')

  new_contents = contents.gsub(/VERSION = '[0-9.]*'/, "VERSION = '#{new_version}'")
  File.write('lib/grpc_web/version.rb', new_contents)
end

def bundle_install
  system('bundle install')
end

def build_gem
  system('gem build grpc-web-ruby.gemspec')
end

set_version
bundle_install
build_gem
