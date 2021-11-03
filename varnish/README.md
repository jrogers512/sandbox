# Varnish Tutorial

# Setup
##  Webservers
On paper, you may run nginx, apache, or the like, and could have more backend infrastructure behind that (nodejs, database, etc).  We just want to demonstrate Varnish loadbalancing a bit, so...  Let's set up 3 webservers.  Let's use three instances of [nginx]():

``` shell
for (( i=1; i <= 5; i++ )); do
  mkdir -p web${i}
  echo "<html><body style='background-color: #$(shuf -i 5-70 -n 1)$(shuf -i 5-70 -n 1)$(shuf -i 5-70 -n 1)80;'>Served from server #${i}</body></html>" > web${i}/index.html
  docker run -it --rm -d -p 808${i}:80 --name web${i} -v $PWD/web${i}:/usr/share/nginx/html nginx
done
 ```

> **NOTE**: When you're done testing, you can kill the containers by executing `docker stop $( docker ps | grep '\sweb' | awk '{print $1}' )`

Now that we've got the webservers running, lets test each to make sure its working ok.

1. Run `docker ps` to see a list of containers running.  We should see 5 web servers:
``` shell
$ docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS                            NAMES
8acfd20fa51e   nginx     "/docker-entrypoint.…"   28 minutes ago   Up 28 minutes   0.0.0.0:8085->80/tcp             web5
88af1a5abd65   nginx     "/docker-entrypoint.…"   28 minutes ago   Up 28 minutes   0.0.0.0:8084->80/tcp             web4
547a3715be08   nginx     "/docker-entrypoint.…"   28 minutes ago   Up 28 minutes   0.0.0.0:8083->80/tcp             web3
bcd1f1df63a3   nginx     "/docker-entrypoint.…"   28 minutes ago   Up 28 minutes   0.0.0.0:8082->80/tcp             web2
4f6ebd4033c5   nginx     "/docker-entrypoint.…"   28 minutes ago   Up 28 minutes   0.0.0.0:8081->80/tcp             web1
```
2. Notice that each has a different entry port beginning with 808x with the last digit matching the number in the name.  Let's look at each of the servers, and confirm the webserver is up and it serves up a page saying "Served from server #x"
   - http://localhost:8081
   - http://localhost:8082
   - http://localhost:8083
   - http://localhost:8084
   - http://localhost:8085

If all goes well, you'll see five different responses from five different servers on ports 8081 through 8085.  If all is well, proceed with setting up the vanrish container which will 'load balance' all incoming requests on port 8080 to one of the five servers.

## Varnish
``` shell
docker container create --name varnish -p 8080:80 varnish
docker cp default.vcl varnish:/etc/varnish
docker start varnish
```

> ***NOTE***: If you'd like to look at varnishlogs, try running ` docker exec -it varnish varnishlog -d`

### Testing
1. First, lets check out the new port, 8080 which is the varnish listener:
   - http://localhost:8085
2. You should see a message telling which of the five webservers that varnish reached out to.  If you reload, you should get a different server due to the VCL's "round robin" configuration.  Typically you probably would make a given client 'stick' to a particular user by keying in the client IP, a session cookie, or something else. 
3. Kill the web3 container: `docker stop web3`, and then refresh repeatedly again, to see if server #3 shows up (it should not.)

## What Else?
Let's take a look at [default.vcl]:
   - **vcl 4.1**: Specifies the version (4.1 is not backwards compatible before varnish 6, so we need to specify the version to make sure we're using a compatible VCL)
   - **import directors**: import allows us to import [vmods](http://varnish-cache.org/vmods/), in this case the 'directors' vmod helps control which backend is used and when.
   -  **backend**: each statement specifies a different 'backend' server (host and port), and probe (health check to test/confirm the backend server is ready to be used)
   - **sub**: [vcl builtin subroutines](https://book.varnish-software.com/4.0/chapters/VCL_Subroutines.html) are used in the varnish state machine for any given request.  We can modify the built-in subroutines to do what we want.  In this case, we're modifying vcl_init and vcl_recv subs to create a round robin director and add all 5 backend web servers to it.
      - ![VCL Builtin Subroutines](https://book.varnish-software.com/3.0/_images/vcl.png)

This is a pretty basic example, using round-robin load balancing.  It would be more common to make caching 'sticky' for a given client (cookie, or maybe source IP) to always use the same backend.

Varnish can do a lot more than simple load balancing:
- Use different backend servers based on url route (https://servername/***route/file***) 
- Support [Edge Side Includes](https://book.varnish-software.com/4.0/chapters/Content_Composition.html#:~:text=Edge%20Side%20Includes%20or%20ESI,flushing%20it%20to%20the%20client.) embedded in html to cache portions of the page with a more distributed backend.
- act as a poor-man's web access firewall using a pretty robust access list (acl) module and the power of VCL to compare strings, source and destination IPs, geolocation, cookies, etc.
- act as a mediation layer to generate json objects from a backend or from logic defined in VCL
- Man in the middle manipulation of session / header values.
- rate limiting / throttling
- and more! 

# See Also
References, inspirations, and good stuff to read:
- https://bash-prompt.net/guides/varnish-loadbalancer-ubuntu-20-04/
- http://book.varnish-software.com/4.0/chapters/Saving_a_Request.html