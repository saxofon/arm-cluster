# ARM cluster

Repo with lab bench setup of a cluster of virtual ARM nodes.
This could in a real live world scenario be a bunch of raspberry pi boards

We can bring it all up automatically via a simple

```
make cluster-up
```

And then we get a detached tmux session and inside it a terminal for each cluster node.
Again, simple command to start working with it :)

```
make cluster-view
```

![Picture with a tmux cluster session and three cluster nodes](docs/cluster-view-3-nodes.png)

## Bring cluster up
```
make cluster-up
```

## Bring cluster down
```
make cluster-down
```

## Add node to cluster
We can create a node X by using "make cluster-nodeX", like this for a first node :
```
make cluster-node1
```
and we can continue add more nodes as needed :
```
make cluster-node2
make cluster-node3
...
```

## node configuration
