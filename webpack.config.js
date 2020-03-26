const path = require('path')

module.exports = {
  mode: 'development',
  entry: {
    web: './src/index.js',
  },
  output: {
    path: path.resolve(__dirname, 'static'),
    filename: '[name].js'
  },
  devtool: 'inline-source-map',
  devServer: {
    contentBase: './static',
    host: '0.0.0.0',
    port: 9000,
    https: true,
    disableHostCheck: true,
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
}

