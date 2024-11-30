#!/bin/bash

aws cloudformation create-stack \
  --stack-name shibaProxyDNS \
  --template-body file://template.dns.yaml \
  --parameters file://parameter.dns.json \
  --capabilities CAPABILITY_NAMED_IAM
