var path = require('path');

module.exports = {
  mode: "production",
  entry: "./client.js",
  resolve: {
    modules: [
      path.resolve(__dirname),
      path.resolve(__dirname, "node_modules"),
      "node_modules",
    ],
    alias: {
      'pb-grpc-web': path.resolve(__dirname, '../pb-js-grpc-web'),
      'pb-grpc-web-text': path.resolve(__dirname, '../pb-js-grpc-web-text'),
      'grpc-web': require.resolve('grpc-web'),
      'google-protobuf': path.dirname(require.resolve('google-protobuf')),
    }
  },
  output: {
    path: path.resolve(__dirname, "../js-client"),
  },
  optimization: {
    minimize: false
  },
};
