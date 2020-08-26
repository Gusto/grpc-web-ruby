import { grpc } from "@improbable-eng/grpc-web";
import { NodeHttpTransport } from "@improbable-eng/grpc-web-node-http-transport";

import {HelloServiceClient} from './pb-ts/hello_pb_service';
import {HelloRequest, EmptyRequest} from './pb-ts/hello_pb';

// Required for grpc-web in a NodeJS environment (vs. browser)
grpc.setDefaultTransport(NodeHttpTransport());

// Usage: node client.js http://server:port nameParam username password
const serverUrl = process.argv[2];
const grpcMethod = process.argv[3];
const username = process.argv[4];
const password = process.argv[5];
const helloName = process.argv[6];

const client = new HelloServiceClient(serverUrl);
const headers = new grpc.Metadata();

if (username && password) {
  const encodedCredentials = Buffer.from(`${username}:${password}`).toString("base64");
  headers.set("Authorization", `Basic ${encodedCredentials}`);
}

if (grpcMethod == 'SayHello') {
  const req = new HelloRequest();
  req.setName(helloName);
  client.sayHello(req, headers, (err, resp) => {
    var result = {
      response: resp && resp.toObject(),
      error: err && err.metadata && err.metadata.headersMap
    }
    // Emit response and/or error as JSON so it can be parsed from Ruby
    console.log(JSON.stringify(result));
  });
}
else if (grpcMethod == 'SayNothing') {
  const req = new EmptyRequest();
  client.sayNothing(req, headers, (err, resp) => {
    var result = {
      response: resp && resp.toObject(),
      error: err && err.metadata && err.metadata.headersMap
    }
    // Emit response and/or error as JSON so it can be parsed from Ruby
    console.log(JSON.stringify(result));
  });
}
else {
  console.log(`Unknown gRPC method ${grpcMethod}`);
}
