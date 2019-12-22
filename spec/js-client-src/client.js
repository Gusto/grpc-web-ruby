// This file is used to build a gRPC-Web javascript client for the
// HelloService in order to support javascript -> ruby integration specs.
//
// It must be compiled with webpack to generate spec/js-client/main.js

const {HelloRequest} = require('hello_pb.js');
const {HelloServiceClient} = require('hello_grpc_web_pb.js');

const grpc = {};
grpc.web = require('grpc-web');

window.HelloRequest = HelloRequest;
window.HelloServiceClient = HelloServiceClient;
