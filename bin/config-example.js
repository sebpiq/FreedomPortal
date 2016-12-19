module.exports = {
  // [required]
  // Web environment in which the user will navigate the captive portal. Valid values :
  //    - cna : the captive portal will open in the captive network assistant.
  //    - full-browser : the captive network assistant will direct the user to a full
  //                     browser before the captive portal is served. 
  webEnv: 'cna|full-browser',

  // [required]
  // Absolute path to the captive portal files, html pages and assets. 
  wwwDir: '/path/to/www/files',

  // [Optional]
  ios: {

    // The HTML page that the user will see in full-browser mode in iOS CNA.
    // The only role of this page is to redirect the user to a browser.
    // Please check "pages/ios/connected.html"
    connectedPagePath: '/path/to/page.html'
  },

  // [Optional]
  android: {

    // The HTML page that the user will see in full-browser mode in Android CNA.
    // The only role of this page is to redirect the user to a browser
    // Please check "pages/android/connected.html"
    connectedPagePath: '/path/to/page.html'
  },

}