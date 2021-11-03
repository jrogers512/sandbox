vcl 4.1;

import directors;

backend web1 {
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

backend web2 {
  .host = "host.docker.internal";
  .port = "8082";
  .probe = {
      .url = "/";
      .timeout = 1s;
      .interval = 5s;
      .window = 5;
      .threshold = 3;
  }
}

backend web3 {
  .host = "host.docker.internal";
  .port = "8083";
  .probe = {
      .url = "/";
      .timeout = 1s;
      .interval = 5s;
      .window = 5;
      .threshold = 3;
  }
}

backend web4 {
  .host = "host.docker.internal";
  .port = "8084";
  .probe = {
      .url = "/";
      .timeout = 1s;
      .interval = 5s;
      .window = 5;
      .threshold = 3;
  }
}

backend web5 {
  .host = "host.docker.internal";
  .port = "8085";
  .probe = {
      .url = "/";
      .timeout = 1s;
      .interval = 5s;
      .window = 5;
      .threshold = 3;
  }
}

sub vcl_init {
    new round_robin_director = directors.round_robin();
    round_robin_director.add_backend(web1);
    round_robin_director.add_backend(web2);
    round_robin_director.add_backend(web3);
    round_robin_director.add_backend(web4);
    round_robin_director.add_backend(web5);

}

sub vcl_recv {
    set req.backend_hint = round_robin_director.backend();
}