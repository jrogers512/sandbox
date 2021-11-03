vcl 4.0;

backend default {
  .host = "host.docker.internal";
  .port = "8081";
  .probe = {
      .url = "/";
      .timeout = 1s;
      .interval = 5s;
      .window = 5;
      .threshold = 3;
  }
}
