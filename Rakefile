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

task :down do
  sh 'docker compose down'
end

task :build do
  sh 'docker compose build'
end

def protoc(output_opts)
  proto_files = Dir[File.join(File.expand_path('spec', __dir__), 'pb-src/**/*.proto')]

  # Generate grpc-web (binary format) JS files
  sh [
       'docker compose run --rm --remove-orphans --entrypoint protoc protoc',
       '--plugin=protoc-gen-js=/usr/lib/node_modules/protoc-gen-js/bin/protoc-gen-js',
       '--plugin=protoc-gen-ts=/usr/bin/protoc-gen-ts',
       '--plugin=protoc-gen-grpc-web=/usr/local/bin/protoc-gen-grpc-web',
       '--plugin=protoc-gen-grpc-ruby=/usr/local/bin/grpc_tools_ruby_protoc_plugin',
       output_opts,
       '-I /defs/pb-src',
       proto_files.map { File.basename(it) }
     ].flatten.join(' ')
end

task compile_protos_js: [:down, :build] do
  protoc %w[
  --js_out=import_style=commonjs:/defs/pb-js-grpc-web
  --grpc-web_out=import_style=commonjs,mode=grpcweb:/defs/pb-js-grpc-web
  ]

  protoc %w[
  --js_out=import_style=commonjs:/defs/pb-js-grpc-web-text
  --grpc-web_out=import_style=commonjs,mode=grpcwebtext:/defs/pb-js-grpc-web-text
  ]
end

task :compile_protos_ruby do
  protoc %w[
  --ruby_out=/defs/pb-ruby
  --grpc-ruby_out=/defs/pb-ruby
  ]
end

task :compile_protos_ts do
  protoc %w[
  --js_out=import_style=commonjs,binary:/defs/pb-ts
  --ts_out=service=grpc-web:/defs/pb-ts
  ]
end

task compile_protos: [:compile_protos_js, :compile_protos_ts, :compile_protos_ruby]

task compile_js_client: [:down, :build, :compile_protos_js] do
  compile_js_cmd = '"cd spec/js-client-src; yarn install; yarn run webpack"'
  sh "docker compose run --rm --use-aliases --remove-orphans ruby #{compile_js_cmd}"
end

task compile_node_client: [:down, :build, :compile_protos_ts] do
  compile_node_cmd = '"cd spec/node-client; yarn install; yarn build"'
  sh "docker compose run --use-aliases --remove-orphans ruby #{compile_node_cmd}"
end

task compile_clients: [:compile_js_client, :compile_node_client]

task compile: [:compile_protos, :compile_clients]

task :run_specs_in_docker do
  sh 'docker compose run --rm --use-aliases --remove-orphans ruby rspec'
end

task default: %i[
  clean
  down
  build
  compile
  run_specs_in_docker
]
