// The source code including full typescript support is available at: 
// https://github.com/shakacode/react_on_rails_demo_ssr_hmr/blob/master/config/webpack/commonWebpackConfig.js

// Common configuration applying to client and server configuration
const { generateWebpackConfig, merge } = require('shakapacker');

const baseClientWebpackConfig = generateWebpackConfig();

const commonOptions = {
  // Or selectively suppress specific warnings:
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
  ignoreWarnings: [
    {
      module: /bootstrap/,  // Ignore warnings from bootstrap
    },
    {
      message: /Deprecation Warning/, // Ignore specific warning messages
    }
  ],
  exclude: [
    /.DS_Store/
  ]
};

// Copy the object using merge b/c the baseClientWebpackConfig and commonOptions are mutable globals
const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions);

module.exports = commonWebpackConfig;
