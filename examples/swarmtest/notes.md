# Reference
https://thenewstack.io/tutorial-deploy-a-full-stack-application-to-a-docker-swarm

## build (on node1)
```
node1$ docker-compose build
```

## push container image to our cluster container registry
```
node1$ docker-compose push
```

## deploy to our cluster
```
node1$ docker stack deploy --compose-file docker-compose.yml swarmtest
```

## test from outside cluster
```
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmtest$ curl http://192.168.100.1:8000
Hello from swarmtest! I have been seen 1 times.
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmtest$ curl http://192.168.100.3:8000
Hello from swarmtest! I have been seen 2 times.
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmtest$
```

## info about swarmtest
```
pi@node1:~/swarmtest$ docker stack services swarmtest
ID             NAME              MODE         REPLICAS   IMAGE                             PORTS
c0m9o7e55y44   swarmtest_redis   replicated   1/1        redis:alpine                      
wngg80k9nar3   swarmtest_web     replicated   1/1        127.0.0.1:5000/swarmtest:latest   *:8000->8000/tcp
pi@node1:~/swarmtest.old $ docker stack ps swarmtest
ID             NAME                IMAGE                             NODE      DESIRED STATE   CURRENT STATE            ERROR     PORTS
s4c6x5cxbwsu   swarmtest_redis.1   redis:alpine                      node2     Running         Running 16 minutes ago             
1bklpinl9p54   swarmtest_web.1     127.0.0.1:5000/swarmtest:latest   node3     Running         Running 16 minutes ago             
pi@node1:~/swarmtest$
```

## bring swarmtest down
```
pi@node1:~/swarmtest$ docker stack rm swarmtest
```

## cleanup swarmtest from the cluster
```
pi@node1:~/swarmtest$ docker rmi 127.0.0.1:5000/swarmtest:latest
```


## HA test
Now it starts to get interesting...

In a terminal, do
```
swarmtest$ watch -n 0.1 curl -s http://192.168.100.1:8000
```

This will be our "swarmtest service up meter"

In another terminal, do
```
arm-cluster$ make node1-shell
```

and we can here look at how the cluster works and run swarmtest
```
pi@node1:~/swarmtest $ docker node ls; docker stack ps swarmtest
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
1j0hjjv8i1u9ljrklss9kbgjc *   node1      Ready     Active         Leader           20.10.24+dfsg1
fm9cj2ycpl1lehr3i8zoy2cmp     node2      Ready     Active         Reachable        20.10.24+dfsg1
cb76tsp20rxrkjh9f1ijmlsmz     node3      Ready     Active         Reachable        20.10.24+dfsg1
ID             NAME                    IMAGE                             NODE                        DESIRED STATE   CURRENT STATE                ERROR                         PORTS
aci7husi169x   swarmtest_redis.1       redis:alpine                      node1                       Running         Running 22 minutes ago
6t7a6n9kwpgj   swarmtest_web.1         127.0.0.1:5000/swarmtest:latest   node2                       Running         Running 3 minutes ago
pi@node1:~/swarmtest $
```
This will be our "swarmtest dashboard", where we see our nodes (status, availability etc) and where our swarmtest app runs its services
Above we see that swarmtest db service runs in node1 and swarmtest web service runs in node2.

We can now bring down node 2 gracefully in yet another terminal
```
arm-cluster$ make node2-down
```

If all goes well we should now have seen in the dashboard that swarmtest web was shutdown for node2,
prepared to be running in node3 (or node1) and finally running again.
```
pi@node1:~/swarmtest $ docker node ls; docker stack ps swarmtest
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
1j0hjjv8i1u9ljrklss9kbgjc *   node1      Ready     Active         Leader           20.10.24+dfsg1
fm9cj2ycpl1lehr3i8zoy2cmp     node2      Ready     Active         Reachable        20.10.24+dfsg1
cb76tsp20rxrkjh9f1ijmlsmz     node3      Ready     Active         Reachable        20.10.24+dfsg1
ID             NAME                    IMAGE                             NODE                        DESIRED STATE   CURRENT STATE                ERROR                         PORTS
aci7husi169x   swarmtest_redis.1       redis:alpine                      node1                       Running         Running 22 minutes ago
mvajouyfs4p    swarmtest_web.1         127.0.0.1:5000/swarmtest:latest   node3                       Running         Running 1 minutes ago
p6t7a6n9kwpgj   \_ swarmtest_web.1     127.0.0.1:5000/swarmtest:latest   node2                       Shutdown        Running about an hour ago
pi@node1:~/swarmtest $
```

And during all this, the service up meter showed swarmtest to be halted, stopped or otherwise unavailable
for a while and then get running again.
In this simple example we cannot know at swarmtest client side, the curl/browse of swarmtest url, what
the reason was for the outage.

Lets try a more brutal "crash" of a node that runs some cluster payload, first we bring up the cluster
to its full again as in this example we are using 3 nodes of role managers, which then needs at least
two nodes up-n-running for the cluster to be working.
```
arm-cluster$ make cluster-node2
```

Use the dashboard to find the node running our web app again, and simply kill the nodes qemu processes
```
arm-cluster$ make node3-kill
```

Things should work in same manner as for a graceful node shutdown.

All-in-all, our high-availability systems running the simple view counter works great!
