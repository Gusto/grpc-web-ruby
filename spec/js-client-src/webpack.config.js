var path = require('path');

module.exports = {
  mode: "production",
  entry: "./client.js",
  resolve: {
    modules: [
      path.resolve(__dirname),
      path.resolve(__dirname, "../pb-js"),
      path.resolve(__dirname, "node_modules"),
    ],
  },
  output: {
    path: path.resolve(__dirname, "../js-client"),
  },
  optimization: {
    minimize: false
  },
};
