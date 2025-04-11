# frozen_string_literal: true

require 'rake/clean'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

CLEAN.include('spec/pb-ruby/*.rb')
CLEAN.include('spec/pb-js-grpc-web/*.js')
CLEAN.include('spec/pb-js-grpc-web-text/*.js')
CLEAN.include('spec/pb-ts/*.js')
CLEAN.include('spec/pb-ts/*.ts')
CLEAN.include('spec/js-client/main.js')
CLEAN.include('spec/node-client/dist/*')

NAMELY_DOCKER_IMAGE = 'namely/protoc-all:1.31_2'

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
  sh RakeHelpers.compile_protos_js_cmd('grpcweb', '/spec/pb-js-grpc-web')
end

task :compile_protos_ruby do
  sh [
    'docker run',
    "-v \"#{File.expand_path('spec', __dir__)}:/defs\"",
    NAMELY_DOCKER_IMAGE,
    '-d /defs/pb-src',
    '-o /defs/pb-ruby',
    '-l ruby',
  ].join(' ')
end

task :compile_protos_ts do
  defs_dir = File.expand_path('spec', __dir__)
  proto_files = Dir[File.join(defs_dir, 'pb-src/**/*.proto')]
  proto_input_files = proto_files.map { |f| f.gsub(defs_dir, '/defs') }
  sh [
    'docker run',
    "-v \"#{defs_dir}:/defs\"",
    '--entrypoint protoc',
    NAMELY_DOCKER_IMAGE,
    '--plugin=protoc-gen-ts=/usr/bin/protoc-gen-ts',
    '--js_out=import_style=commonjs,binary:/defs/pb-ts',
    '--ts_out=service=grpc-web:/defs/pb-ts',
    '-I /defs/pb-src',
    proto_input_files.join(' '),
  ].join(' ')
end

task compile_js_client: [:compile_protos_js] do
  compile_js_cmd = '"cd spec/js-client-src; yarn install; yarn run webpack"'
  sh [
    'docker-compose down',
    'docker-compose build',
    "docker-compose run --use-aliases ruby #{compile_js_cmd}",
    'docker-compose down',
  ].join(' && ')
end

task compile_node_client: [:compile_protos_ts] do
  compile_node_cmd = '"cd spec/node-client; yarn install; yarn build"'
  sh [
    'docker-compose down',
    'docker-compose build',
    "docker-compose run --use-aliases ruby #{compile_node_cmd}",
    'docker-compose down',
  ].join(' && ')
end

task :run_specs_in_docker do
  sh [
    'docker-compose down',
    'docker-compose build',
    'docker-compose run --use-aliases ruby rspec',
    'docker-compose down',
  ].join(' && ')
end

task default: %i[
  clean
  compile_protos_ruby
  compile_js_client
  compile_node_client
  run_specs_in_docker
]
