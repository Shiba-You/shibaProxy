#!/bin/bash

aws cloudformation create-stack \
  --stack-name shibaProxyVPC \
  --template-body file://template.vpc.yaml \
  --parameters file://parameter.vpc.json \
  --capabilities CAPABILITY_NAMED_IAM
