function fn() {
  var config = {
    baseUrl: 'https://api.demoblaze.com',
    connectTimeout: 10000,
    readTimeout: 10000
  };

  karate.configure('ssl', true);
  karate.configure('connectTimeout', config.connectTimeout);
  karate.configure('readTimeout', config.readTimeout);

  return config;
}
