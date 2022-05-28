#!/bin/bash
docker run -p 29092:29092 --network kafka --hostname kafka-1 --env-file envkafka confluentinc/cp-kafka:4.1.2-2