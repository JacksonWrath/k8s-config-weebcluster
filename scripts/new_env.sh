#!/bin/zsh

set -e

root_dir=$(git rev-parse --show-toplevel)

if [ -z $1 ]; then
    echo "Must provide environment name"
    exit 1
fi

if [ -z $2 ]; then
    env_name=$1
else
    env_name=$2
fi

if [ -z $3 ]; then
    namespace=$1
else
    namespace=$3
fi

env_dir=$root_dir/tanka/environments/$1

mkdir $env_dir

cat $root_dir/scripts/env_template.jsonnet | sed "s/ENV_NAME/$env_name/g" | sed "s/NAMESPACE/$namespace/g" > $env_dir/main.jsonnet

