# gRPC-Web Ruby

[![Gusto](https://circleci.com/gh/Gusto/grpc-web-ruby/tree/master.svg?style=shield&circle-token=062a6c1a39b142a123eefe766baf90c51f8dd699)](https://circleci.com/gh/Gusto/grpc-web-ruby/tree/master)

## Background
Host gRPC-Web endpoints for Ruby gRPC services in a Rails or Rack app (over HTTP/1). Client included.

### gRPC vs gRPC-Web

gRPC-Web is a variation of the gRPC protocol adapted to function over an HTTP/1 connection. This allows gRPC services to be accessed by web browser clients and using infrastructure that does not support end-to-end HTTP/2 load balancing like AWS ELBs and ALBs. ALBs only support HTTP/2 client -> LB not LB -> service.

### Use Cases for gRPC-Web

1. **Client -> Server:** Access typed gRPC + Protobuf APIs from javascript in the browser.
2. **Service <-> Service:** Communicate between services using typed gRPC + Protobuf APIs over existing HTTP/1 infrastructure and load balancing solutions.

### More Information
[gRPC-Web Introductory Blog Post](https://grpc.io/blog/grpc-web-ga/)

[gRPC-Web Protocol (with comparison against gRPC)](https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-WEB.md)

## Compatibility

#### Supported Content Types
1. application/grpc-web
1. application/grpc-web+proto
1. application/grpc-web+json
1. application/grpc-web-text (base64 encoded)
1. application/grpc-web-text+proto (base64 encoded)

#### Integration testing

gRPC-Web Ruby includes integration tests between the following implementations of gRPC-Web:
1. Ruby Client with Ruby Server
2. Javascript Client with Ruby Server
3. Ruby Client with Envoy Proxy Server

## Getting Started
Add the gem to your Gemfile:
```ruby
gem 'grpc-web'
```

### Implement a gRPC Service in Ruby
Build a service using the standard [Ruby gRPC library](https://github.com/grpc/grpc/tree/master/src/ruby) or use any existing ruby gRPC service. For a more complete introduction to gRPC in Ruby checkout the [gRPC Ruby Quickstart](https://grpc.io/docs/quickstart/ruby/).

#### Define the service API using Protobuf
```protobuf
# hello.proto
syntax = "proto3";

message HelloRequest {
  string name = 1;
}

message HelloResponse {
  string message = 1;
}

service HelloService {
  rpc SayHello(HelloRequest) returns (HelloResponse);
}

```

#### Generate ruby code
```ruby
# hello_pb.rb
require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("hello.proto", :syntax => :proto3) do
    add_message "HelloRequest" do
      optional :name, :string, 1
    end
    add_message "HelloResponse" do
      optional :message, :string, 1
    end
  end
end

HelloRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("HelloRequest").msgclass
HelloResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("HelloResponse").msgclass
```

```ruby
# hello_services_pb.rb
require 'grpc'
require 'hello_pb'

module HelloService
  class Service

    include GRPC::GenericService

    self.marshal_class_method = :encode
    self.unmarshal_class_method = :decode
    self.service_name = 'HelloService'

    rpc :SayHello, HelloRequest, HelloResponse
  end

  Stub = Service.rpc_stub_class
end
```

#### Implement the service

```ruby
# example_hello_service.rb
require 'hello_services_pb'

class ExampleHelloService < HelloService::Service
  def say_hello(request, _call = nil)
    return HelloResponse.new(message: "Hello #{request.name}")
  end
end
```

### Run a gRPC-Web Server
You can run a gRPC-Web server using any Rack compliant HTTP server such as WEBrick, Unicorn, or Puma. You can also mount gRPC-Web endpoints alongside a Rails, Sinatra, or other Rack application.

#### Running with WEBrick
```ruby
# example_grpc_web_server.rb
require 'grpc_web'
require 'example_hello_service'
require 'rack/handler'

GRPCWeb.handle(ExampleHelloService)
Rack::Handler::WEBrick.run GRPCWeb.rack_app
```

#### Running with Basic Auth
Since you can run a gRPC-Web server using any Rack compliant app, you can accordingly support basic authentication for the server as well.

```ruby
# example_grpc_web_server.rb
require 'grpc_web'
require 'example_hello_service'
require 'rack/handler'

GRPCWeb.rack_app.use Rack::Auth::Basic do |username, password|
  [user, password] == ["foobar", "verysecret"]
end

GRPCWeb.handle(ExampleHelloService)

Rack::Handler::WEBrick.run GRPCWeb.rack_app
```

Now you can point your client to a Basic Auth comformant URL for this rack service. Example: `http://foobar:verysecret@localhost:3000/grpc`. Or via authentication headers, which ever is best suited by the client.

## Configuring Services

Like the standard gRPC **RpcServer** class, `GRPCWeb.handle` accepts either an instance of a service or a service class. gRPC-Web also supports a block syntax for `.handle` that enables lazy loading of service classes.

#### Instance of a service
```ruby
GRPCWeb.handle(ExampleHelloService.new('initializer argument'))
```

#### Service class
When a service class is provided a new instance will be created for each request using `.new`.

```ruby
GRPCWeb.handle(ExampleHelloService)
```

#### Lazy initialization block
The argument to `.handle` is the service interface class (generated from proto) when using a lazy init block.

```ruby
GRPCWeb.handle(HelloService::Service) do
  require 'example_hello_service'
  ExampleHelloService.new
end
```

## Integration with Rails
gRPC-Web Ruby is designed to integrate easily with an existing Ruby on Rails application.

#### Mount gRPC-Web in the Rails route file
```ruby
# config/routes.rb
require 'grpc_web'

Rails.application.routes.draw do
  mount GRPCWeb.rack_app => '/grpc'
  ...
end
```

#### Configure services in an initializer
```ruby
# config/initializers/grpc_web.rb
require 'hello_services_pb'

GRPCWeb.handle(HelloService::Service) do
  require_dependency 'example_hello_service'
  ExampleHelloService.new
end
```

## Using the Ruby Client
The gRPC-Web Ruby client is tested to be compatible with both the gRPC-Web Ruby server and the Envoy gRPC-Web proxy.

#### Creating a client
```ruby
require 'grpc_web/client'
require 'hello_services_pb'

$client = GRPCWeb::Client.new("http://localhost:3000/grpc", HelloService::Service)
```

#### Calling a method
```ruby
$client.say_hello(name: 'James')
# => <HelloResponse: message: "Hello James">
```

#### Using Basic Auth
gRPC-Web Ruby client supports Basic Auth out of the box. You can pass in a Basic Auth comformant URL and gRPC-Web Ruby client will take care of the rest when interacting with the server.

```ruby
$client = GRPCWeb::Client.new("http://foobar:verysecret@localhost:3000/grpc", HelloService::Service)
```

### Error Handling

The gRPC-Web Ruby client and server libraries support the propagation of exceptions using the standard `grpc-status` and `grpc-message` trailers.

gRPC-Web uses the [standard error classes from the core grpc library](https://github.com/grpc/grpc/blob/master/src/ruby/lib/grpc/errors.rb). Any instance or subclass of `GRPC::BadStatus` thrown in a service implementation will propoagate across the wire and be raised as an exception of the same class on the client side. Any other `Error` will be treated as a `GRPC::Unknown`.

### Configuring an on_error callback
```ruby
# config/initializers/grpc_web.rb
GRPCWeb.on_error do |ex, service, service_method|
  ErrorNotifier.notify(ex, metadata: { service: service.class.service_name, method: service_method})
end
```

## Additional Notes

### CORS Middleware (for browser clients)

Web Browser clients will only allow HTTP requests to be made to your gRPC-Web API if CORS headers are correctly configured or the request is sameorigin (the gRPC-Web endpoints are hosted on the same domain that served the javascript code). You will need to use a library like [cyu/rack-cors](https://github.com/cyu/rack-cors) to manage CORS if you want to support browsers.


## Contributing

See the [developer's guide](CONTRIBUTING.md)

## Useful links

gRPC-Web Repo (protoc generator, js-client, proxy server)
https://github.com/grpc/grpc-web

Improbable Eng gRPC Repo (js-client w/ TypeScript + NodeJS support, golang server)
https://github.com/improbable-eng/grpc-web
