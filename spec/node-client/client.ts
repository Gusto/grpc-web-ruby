import { grpc } from "@improbable-eng/grpc-web";
import { NodeHttpTransport } from "@improbable-eng/grpc-web-node-http-transport";

import {HelloServiceClient} from './pb-ts/hello_pb_service';
import {HelloRequest} from './pb-ts/hello_pb';

// Required for grpc-web in a NodeJS environment (vs. browser)
grpc.setDefaultTransport(NodeHttpTransport());

const client = new HelloServiceClient("http://localhost:8080");
const req = new HelloRequest();
req.setName("James");

client.sayHello(req, (err, resp) => {
  var result = {
    response: resp && resp.toObject(),
    error: err
  }
  console.log(JSON.stringify(result));
  // console.log(resp && resp.getMessage());
});
