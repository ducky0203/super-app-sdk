module.exports = {
  dependency: {
    platforms: {
      android: {
        sourceDir: './android',
        packageImportPath: 'import vn.tng.superappsdk.SuperAppBridgePackage;',
        packageInstance: 'new SuperAppBridgePackage()',
      },
      ios: {
        podspecPath: require('path').join(__dirname, 'super-app-sdk.podspec'),
      },
    },
  },
};
