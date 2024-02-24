# references
https://distribution.github.io/distribution
https://lucasroesler.com/posts/2017/docker-registries-in-docker-swarm/

## create
```
docker service create --name registry --publish published=5000,target=5000 registry:2
```


## view images
```
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmregistry$ curl http://192.168.100.1:5000/v2/_catalog
{"repositories":["swarmtest"]}
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmregistry$ curl http://192.168.100.1:5000/v2/swarmtest/tags/list
{"name":"swarmtest","tags":["latest"]}
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmregistry$
```

## simplified view
```
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmregistry$ ./list-registry.sh 
swarmtest
    latest
per@home:~/fs/data/projects/home-cloud/arm-cluster/examples/swarmregistry$
```
