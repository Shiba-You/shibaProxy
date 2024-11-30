#!/bin/bash

aws cloudformation create-stack \
  --stack-name shibaProxyBastion \
  --template-body file://template.bastion.yaml \
  --parameters file://parameter.bastion.json \
  --capabilities CAPABILITY_NAMED_IAM
