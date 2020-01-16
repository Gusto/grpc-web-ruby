require 'rake/clean'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

CLEAN.include('spec/pb-ruby/*.rb')
CLEAN.include('spec/pb-js-grpc-web/*.js')
CLEAN.include('spec/pb-js-grpc-web-text/*.js')
CLEAN.include('spec/js-client/main.js')

module RakeHelpers
  def self.compile_protos_js_cmd(mode, output_dir)
    [
      'docker run',
      "-v \"#{File.expand_path('spec/pb-src', __dir__)}:/protofile\"",
      "-v \"#{File.expand_path('spec', __dir__)}:/spec\"",
      '-e "protofile=hello.proto"',
      "-e \"output=#{output_dir}\"",
      '-e "import_style=commonjs"',
      "-e \"mode=#{mode}\"",
      'juanjodiaz/grpc-web-generator',
    ].join(' ')
  end
end

task :compile_protos_js do
  sh RakeHelpers.compile_protos_js_cmd('grpcwebtext', '/spec/pb-js-grpc-web-text')
  sh 'ls -laR spec'
  #touch 'spec/pb-js-grpc-web-text/.gitkeep'
  sh RakeHelpers.compile_protos_js_cmd('grpcweb', '/spec/pb-js-grpc-web')
  #touch 'spec/pb-js-grpc-web/.gitkeep'
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

task :docker_pull_envoy do
  sh 'docker pull envoyproxy/envoy:latest'
end

task compile_js_client: [:compile_protos_js] do
  Dir.chdir('spec/js-client-src') do
    system('yarn install')
    system('yarn run webpack')
  end
end

task default: [:clean, :compile_protos_ruby, :compile_js_client, :docker_pull_envoy, :spec]
