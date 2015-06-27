#!/bin/bash

usage () {
     echo -e "\nUsage: kolab-worker.sh <start|stop|setup|connect> example.org"
}

load_config () {
if [ -f /etc/kolab-docker/$1 ]; then
    source /etc/kolab-docker/$1
else
    usage
    echo -e "\nconfig /etc/kolab-docker/$1 - not found\n"
    exit 1
fi
}

if [ "$1" = "start" ]; then
    load_config $2
    #docker start -a $DOCKER_NAME
    if [ "$(docker ps -a | grep -c $DOCKER_NAME)" = "0" ]; then 
        docker run --name $DOCKER_NAME -h $DOCKER_HOSTNAME -v $DOCKER_VOLUME:/data:rw $DOCKER_OPTIONS -d kvaps/kolab
        pipework $EXT_INTERFACE -i eth2 $DOCKER_NAME $EXT_ADDRESS@$EXT_GATEWAY
        pipework $INT_BRIDGE -i eth1 $DOCKER_NAME $INT_ADDRESS
        docker exec $DOCKER_NAME $INT_ROUTE
        docker exec ${DOCKER_NAME} bash -c 'echo 127.0.0.1 $(hostname -s) $(hostname -f) >> /etc/hosts'
        docker exec $DOCKER_NAME ifconfig eth2 mtu 1446
    else
        echo "containr already exist"
        exit 1
    fi

elif [ "$1" = "stop" ]; then
    load_config $2
    docker stop $DOCKER_NAME
    docker rm $DOCKER_NAME
elif [ "$1" = "setup" ]; then
    load_config $2
    echo docker run --name $DOCKER_NAME -h $DOCKER_HOSTNAME -v $DOCKER_VOLUME:/data:rw -ti kvaps/kolab
    docker run --name $DOCKER_NAME -h $DOCKER_HOSTNAME -v $DOCKER_VOLUME:/data:rw -ti kvaps/kolab
    docker rm $DOCKER_NAME
elif [ "$1" = "connect" ]; then
    load_config $2
    docker exec -ti $DOCKER_NAME /bin/bash
else
    usage
    echo -e "\naction not set\n"
    exit 1
fi
