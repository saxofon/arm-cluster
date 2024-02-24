#!/bin/bash

registry=http://192.168.100.1:5000

repos=$(curl -s $registry/v2/_catalog | jq -rc .[][])


for repo in $repos; do
	echo "$repo"
	tags=$(curl -s $registry/v2/$repo/tags/list | jq -rc . | cut -d\" -f8)
	for tag in $tags; do
		echo "    $tag"
	done
done
