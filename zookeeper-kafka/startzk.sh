#!/bin/bash
docker run -p 22181:22181 --network kafka --env-file env1 --hostname zookeeper-1 confluentinc/cp-zookeeper:3.3.0-1