#!/bin/bash

aws cloudformation create-stack \
  --stack-name shibaProxyClient \
  --template-body file://template.client.yaml \
  --parameters file://parameter.client.json \
  --capabilities CAPABILITY_NAMED_IAM
