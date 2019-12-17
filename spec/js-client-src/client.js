const {HelloRequest} = require('hello_pb.js');
const {HelloServiceClient} = require('hello_grpc_web_pb.js');

const grpc = {};
grpc.web = require('grpc-web');

window.HelloRequest = HelloRequest;
window.helloService = new HelloServiceClient('http://localhost:8080', null, null);

x = new HelloRequest()
x.setName("James")
window.helloService.sayHello(x, {}, function(err, response){ console.log(err, response); });
