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

task :compile_protos_js do
  defs_dir = File.expand_path('spec', __dir__)
  proto_files = Dir[File.join(defs_dir, 'pb-src/**/*.proto')]
  proto_input_files = proto_files.map { it.gsub(defs_dir, '/defs') }

  # Build the protoc container first
  sh 'docker compose down && docker compose build'

  # Generate grpc-web (binary format) JS files
  sh [
    'docker compose run --remove-orphans --entrypoint protoc protoc',
    '--plugin=protoc-gen-js=/usr/lib/node_modules/protoc-gen-js/bin/protoc-gen-js',
    '--plugin=protoc-gen-grpc-web=/usr/local/bin/protoc-gen-grpc-web',
    '--js_out=import_style=commonjs:/defs/pb-js-grpc-web',
    '--grpc-web_out=import_style=commonjs,mode=grpcweb:/defs/pb-js-grpc-web',
    '-I /defs/pb-src',
    proto_input_files.join(' '),
  ].join(' ')

  # Generate grpc-web-text (base64 format) JS files
  sh [
    'docker compose run --remove-orphans --entrypoint protoc protoc',
    '--plugin=protoc-gen-js=/usr/lib/node_modules/protoc-gen-js/bin/protoc-gen-js',
    '--plugin=protoc-gen-grpc-web=/usr/local/bin/protoc-gen-grpc-web',
    '--js_out=import_style=commonjs:/defs/pb-js-grpc-web-text',
    '--grpc-web_out=import_style=commonjs,mode=grpcwebtext:/defs/pb-js-grpc-web-text',
    '-I /defs/pb-src',
    proto_input_files.join(' '),
  ].join(' ')
end

task :compile_protos_ruby do
  defs_dir = File.expand_path('spec', __dir__)
  proto_files = Dir[File.join(defs_dir, 'pb-src/**/*.proto')]
  proto_input_files = proto_files.map { it.gsub(defs_dir, '/defs') }
  sh [
    'docker compose down &&',
    'docker compose build &&',
    'docker compose run --remove-orphans --entrypoint grpc_tools_ruby_protoc protoc',
    '--ruby_out=/defs/pb-ruby',
    '--grpc_out=/defs/pb-ruby',
    '-I /defs/pb-src',
    proto_input_files.join(' '),
  ].join(' ')
end

task :compile_protos_ts do
  defs_dir = File.expand_path('spec', __dir__)
  proto_files = Dir[File.join(defs_dir, 'pb-src/**/*.proto')]
  proto_input_files = proto_files.map { it.gsub(defs_dir, '/defs') }
  sh [
    'docker compose down &&',
    'docker compose build &&',
    'docker compose run --remove-orphans --entrypoint protoc protoc',
    '--plugin=protoc-gen-js=/usr/lib/node_modules/protoc-gen-js/bin/protoc-gen-js',
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
    'docker compose down',
    'docker compose build',
    "docker compose run --use-aliases --remove-orphans ruby #{compile_js_cmd}",
  ].join(' && ')
end

task compile_node_client: [:compile_protos_ts] do
  compile_node_cmd = '"cd spec/node-client; yarn install; yarn build"'
  sh [
    'docker compose down',
    'docker compose build',
    "docker compose run --use-aliases --remove-orphans ruby #{compile_node_cmd}",
  ].join(' && ')
end

task :run_specs_in_docker do
  sh [
    'docker compose down',
    'docker compose build',
    'docker compose up -d selenium envoy',
    'docker compose run --use-aliases --remove-orphans ruby rspec --fail-fast --seed 1234 --format documentation',
    'docker compose down',
  ].join(' && ')
end

task default: %i[
  clean
  compile_protos_ruby
  compile_js_client
  compile_node_client
  run_specs_in_docker
]
