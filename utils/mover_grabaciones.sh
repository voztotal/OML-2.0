#!/bin/bash

for j in $(seq -w 08 10);do
  for i in $(seq -w 30 31); do
    aws s3 cp s3://prod-freetech-konecta-data/2020-10-$i/ s3://prod-freetech-hipotecario-data/2020-10-$i --recursive
  done
done
