// This file is used to build a gRPC-Web javascript client for the
// HelloService in order to support javascript -> ruby integration specs.
//
// It must be compiled with webpack to generate spec/js-client/main.js

const {HelloRequest} = require('pb-grpc-web/hello_pb.js');

// This version of the JS client makes requests as application/grpc-web (binary):
const HelloClientWeb = require('pb-grpc-web/hello_grpc_web_pb.js');

// This version of the JS client makes requests as application/grpc-web-text (base64):
const HelloClientWebText = require('pb-grpc-web-text/hello_grpc_web_pb.js');

const grpc = {};
grpc.web = require('grpc-web');

window.HelloRequest = HelloRequest;
window.HelloServiceClientWeb = HelloClientWeb.HelloServiceClient;
window.HelloServiceClientWebText = HelloClientWebText.HelloServiceClient;
