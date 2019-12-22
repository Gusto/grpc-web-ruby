require 'rake/clean'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

CLEAN.include('spec/pb-ruby/*')
CLEAN.include('spec/pb-js/*')
CLEAN.include('spec/js-client/main')

task :compile_protos_js do
  sh [
    'docker run',
    "-v \"#{File.expand_path('spec/pb-src', __dir__)}:/protofile\"",
    "-v \"#{File.expand_path('spec', __dir__)}:/spec\"",
    '-e "protofile=hello.proto"',
    '-e "output=/spec/pb-js"',
    '-e "import_style=commonjs"',
    'juanjodiaz/grpc-web-generator',
  ].join(' ')
end

task :compile_protos_ruby do
  sh [
    'docker run',
    "-v \"#{File.expand_path('spec', __dir__)}:/defs\"",
    'namely/protoc-all',
    '-d /defs/pb-src',
    '-o /defs/pb-ruby',
    '-l ruby',
  ].join(' ')
end

task compile_js_client: [:compile_protos_js] do
  Dir.chdir('spec/js-client-src') do
    system('yarn install')
    system('yarn run webpack')
  end
end

task default: [:clean, :compile_protos_ruby, :compile_js_client, :spec]
