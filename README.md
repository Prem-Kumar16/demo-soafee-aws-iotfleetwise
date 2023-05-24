# Welcome to the SOAFEE AWS IoT Fleetwise demo

The repository contains the instructions and code that allows you to reproduce the demo shown in the session [**Achieving environmental parity through multiple layers of abstractions helps to support AWS IoT FleeWise edge on EWAOL**](https://www.youtube.com/watch?v=Wd1isAmTtp8) at [SOAFEE Virtual Symposium 2022](https://soafee.io/blog/2022/virtual_symposium/).

The demo will walk you through the exercise of running on [EWAOL](https://github.com/aws4embeddedlinux/meta-aws-ewaol) the [AWS IoT FleeWise](https://aws.amazon.com/iot-fleetwise/) Edge. The [AWS IoT FleeWise Edge](https://github.com/aws/aws-iot-fleetwise-edge) will run in a [container](https://gallery.ecr.aws/aws-iot-fleetwise-edge/aws-iot-fleetwise-edge) and the orchestration will be done with [k3s](https://k3s.io/). We can use the exact same container image both in the cloud and on a physical target, as long as they are based on an ARM v8 core.

This demo is solely implemented on the custom built yocto linux AMI that is specialized for SDV ( Software Defined Vehicle ) purposes

## Getting started

## THIS DEMO WILL ONLY WORK ON FRANKFURT (eu-central-1) region 

Deploy EC2 in Frankfurt region

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/eu-central-1.svg)](https://eu-central-1.console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/quickcreate?templateURL=https%3A%2F%2Fs3.eu-central-1.amazonaws.com%2Fcf-templates-fui01m96flo3-eu-central-1%2F2023-05-24T071122.004Z5n6-ec2-template.yml&stackName=ewaol-ec2-creation)

Acknowledge the creation of the stack and press the button **Create stack** on the bottom right. 

The ```ewaol-ec2-creation``` CloudFormation stack will take about **2 minutes** to be created.

### Locally downloading the Private key file

Follow the steps below to download the private .pem key file to SSH into the instance

Open cloudshell and run the following command

```sh 
aws ec2 describe-key-pairs --filters Name=key-name,Values=keypair-for-ewaol --query KeyPairs[*].KeyPairId --output text
```
The output will be the key ID. Note down it

Run the below command to save .pem file in the cloudshell directory

Change the keyid paramater to the output of previous command

```sh
aws ssm get-parameter --name /ec2/keypair/<keyid here> --with-decryption --query Parameter.Value --output text > keypair-for-ewaol.pem
```

Go to actions -> download file and paste this path "/home/cloudshell-user/keypair-for-ewaol.pem" inside the path field to save .pem key file locally

If you go to ec2 instances page, you will find a newly created instance named "EWAOL-Instance". SSH into the instance using the key file  that you have previously downloaded

Run the following script to create the cdk stack that will deploy all the cloud resources as shown on the architecture above

#### Important note, while SSH change the user name from root to ewaol i.e., instead of root@ip.eu-central-1.compute.amazonaws.com, you should use ewaol@ip.eu-central-1.compute.amazonaws.com

After connected to the instance via SSH, run the below command

Note : Give the access & secret access key to the instance via "aws configure" command & the default region name must be eu-central-1

```sh
aws configure
git clone https://github.com/Prem-Kumar16/demo-soafee-aws-iotfleetwise.git
cd demo-soafee-aws-iotfleetwise/
./scripts/deploy-cloud.sh
```

The above commands will take about **10 minutes** to complete. While you wait we encorage you to appreciate how the cloud resources gets deployed through [CDK](https://aws.amazon.com/cdk/) leveraging the [AWS IoT FleetWise Construct Library](https://github.com/aws-samples/cdk-aws-iotfleetwise) having a look to [this file](https://github.com/aws-samples/demo-soafee-aws-iotfleetwise/blob/main/cloud/src/main.py).

### Get AWS FleetWise Edge running on the Build Host

```sh
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
```

Build the Vehicle Simulator container image that will feeding signals on the CAN Bus Data where the AWS IoT FleetWise Edge is listening on

```sh
sudo ./scripts/build-vsim.sh
```

Load certificate and private key for the vehicle into k3s secrets. These have been created by ```./scripts/deploy-cloud.sh``` above

```sh
sudo /usr/local/bin/kubectl create secret generic private-key --from-file=./.tmp/private-key.key
sudo /usr/local/bin/kubectl create secret generic certificate --from-file=./.tmp/certificate.pem
```

Deploy the kubernetes manifest to k3s

```sh
./scripts/deploy-k3s.sh
```
The script shows you the AWS IoT FleetWise Edge log. If you stop the script with CTRL+C, this will terminate the containers. As such, if you want to run other commands without stopping the containers, open another terminal.

Now you can connect to the Vehicle Simulator Webapp by opening the "http://<your public ip>:8080"

You can try changing things such as opening/closing the vehicle doors and observe how the data signals values are fed into our Amazon Timestream table. You can either use [Amazon Timestream console](https://console.aws.amazon.com/timestream/home?#query-editor:) to run the query or you can paste the command below in one of the terminals.

```sh
aws timestream-query query --query-string \
  "SELECT * FROM FleetWise.FleetWise WHERE time > ago(5m) ORDER BY time DESC LIMIT 2" \
  | jq -r '.Rows[].Data[].ScalarValue'
```

Please note that DoorsState is encoded on 5 bits and the value associated with each door is shown below. The left and right reference are from the point of view of facing the road ahead, while seated inside the vehicle.

|Value|Door|
|-|-|
|1|Front left|
|2|Front right|
|4|Rear left|
|8|Rear right|
|16|Vehicle trunk lid|

### Get AWS FleetWise Edge running on an EWAOL Virtual Target 

> :warning: THIS SECTION IS UNDER CONSTRUCTION, STAY TUNED !!!

### Get AWS FleetWise Edge running on an EWAOL Physical Target 

> :warning: THIS SECTION IS UNDER CONSTRUCTION, STAY TUNED !!!

### Cleanup

From [CloudFormation](https://console.aws.amazon.com/cloudformation/home) just delete `demo-soafee-aws-iotfleetwise` and `ewaol-ec2-creation` stacks.

---

This repository depends on and may incorporate or retrieve a number of third-party
software packages (such as open source packages) at install-time or build-time
or run-time ("External Dependencies"). The External Dependencies are subject to
license terms that you must accept in order to use this package. If you do not
accept all of the applicable license terms, you should not use this package. We
recommend that you consult your company’s open source approval policy before
proceeding.

Provided below is a list of External Dependencies and the applicable license
identification as indicated by the documentation associated with the External
Dependencies as of Amazon's most recent review.

THIS INFORMATION IS PROVIDED FOR CONVENIENCE ONLY. AMAZON DOES NOT PROMISE THAT
THE LIST OR THE APPLICABLE TERMS AND CONDITIONS ARE COMPLETE, ACCURATE, OR
UP-TO-DATE, AND AMAZON WILL HAVE NO LIABILITY FOR ANY INACCURACIES. YOU SHOULD
CONSULT THE DOWNLOAD SITES FOR THE EXTERNAL DEPENDENCIES FOR THE MOST COMPLETE
AND UP-TO-DATE LICENSING INFORMATION.

YOUR USE OF THE EXTERNAL DEPENDENCIES IS AT YOUR SOLE RISK. IN NO EVENT WILL
AMAZON BE LIABLE FOR ANY DAMAGES, INCLUDING WITHOUT LIMITATION ANY DIRECT,
INDIRECT, CONSEQUENTIAL, SPECIAL, INCIDENTAL, OR PUNITIVE DAMAGES (INCLUDING
FOR ANY LOSS OF GOODWILL, BUSINESS INTERRUPTION, LOST PROFITS OR DATA, OR
COMPUTER FAILURE OR MALFUNCTION) ARISING FROM OR RELATING TO THE EXTERNAL
DEPENDENCIES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, EVEN
IF AMAZON HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. THESE LIMITATIONS
AND DISCLAIMERS APPLY EXCEPT TO THE EXTENT PROHIBITED BY APPLICABLE LAW.


vsim/Dockerfile depends on third party **docker/library/node** container image, please refer to [license section](https://gallery.ecr.aws/docker/library/node) 

vsim/Dockerfile depends on third party **docker/library/python** container image, please refer to [license section](https://gallery.ecr.aws/docker/library/python)
