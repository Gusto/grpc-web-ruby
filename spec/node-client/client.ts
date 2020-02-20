import { grpc } from "@improbable-eng/grpc-web";
import { NodeHttpTransport } from "@improbable-eng/grpc-web-node-http-transport";

import {HelloServiceClient} from './pb-ts/hello_pb_service';
import {HelloRequest} from './pb-ts/hello_pb';

// Required for grpc-web in a NodeJS environment (vs. browser)
grpc.setDefaultTransport(NodeHttpTransport());

const serverUrl = process.argv[2];
const name = process.argv[3];

const client = new HelloServiceClient(serverUrl);
const req = new HelloRequest();
req.setName(name);

client.sayHello(req, (err, resp) => {
  var result = {
    response: resp && resp.toObject(),
    error: err && err.metadata && err.metadata.headersMap
  }
  // Emit response and/or error as JSON so it can be parsed from Ruby
  console.log(JSON.stringify(result));
});
