module.exports = {
  // Web environment in which the user will navigate the captive portal. Valid values :
  //    - cna : the captive portal will open in the captive network assistant.
  //    - full-browser : the captive network assistant will direct the user to a full
  //                     browser before the captive portal is served. 
  webEnv: 'cna|full-browser',

  // Absolute path to the captive portal files, html pages and assets. 
  wwwDir: '/path/to/www/files'
}