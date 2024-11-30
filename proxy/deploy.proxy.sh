#!/bin/bash

aws cloudformation create-stack \
  --stack-name shibaProxyProxy \
  --template-body file://template.proxy.yaml \
  --parameters file://parameter.proxy.json \
  --capabilities CAPABILITY_NAMED_IAM
