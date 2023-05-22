#!/bin/bash
set -euo pipefail


export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=eu-central-1
echo "export ACCOUNT_ID=${ACCOUNT_ID}"
echo "export AWS_REGION=${AWS_REGION}"
aws configure set default.region ${AWS_REGION}
aws configure set default.account ${ACCOUNT_ID}
git config --global core.autocrlf false
aws cloudformation create-stack \
  --stack-name CDKToolkit \
  --template-url https://2054864-template-for-iotfw.s3.eu-central-1.amazonaws.com/bootstrap-template.yml \
  --capabilities CAPABILITY_NAMED_IAM


mkdir -p .tmp
pushd cloud
python3.10 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install --upgrade pip
pip install nodeenv
nodeenv -p
npm install -g npm@latest
sudo npm install aws-cdk -g
cdk deploy --require-approval never --outputs-file ../.tmp/cdk-outputs.json
deactivate
popd

aws cloudformation describe-stacks --region eu-central-1 --query "Stacks[?StackName=='demo-soafee-aws-iotfleetwise'][].Outputs[?OutputKey=='certificate'].OutputValue" --output text > .tmp/certificate.pem

aws cloudformation describe-stacks --region eu-central-1 --query "Stacks[?StackName=='demo-soafee-aws-iotfleetwise'][].Outputs[?OutputKey=='endpointAddress'].OutputValue" --output text > .tmp/endpoint_address.txt

aws cloudformation describe-stacks --region eu-central-1 --query "Stacks[?StackName=='demo-soafee-aws-iotfleetwise'][].Outputs[?OutputKey=='privateKey'].OutputValue" --output text > .tmp/private-key.key

aws cloudformation describe-stacks --region eu-central-1 --query "Stacks[?StackName=='demo-soafee-aws-iotfleetwise'][].Outputs[?OutputKey=='vehicleName'].OutputValue" --output text > .tmp/vehicle_name.txt

aws cloudformation describe-stacks --region eu-central-1 --query "Stacks[?StackName=='demo-soafee-aws-iotfleetwise'][].Outputs[?OutputKey=='vehicleCanInterface'].OutputValue" --output text > .tmp/vehicle_can_interface.txt
