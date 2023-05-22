# Securing Serverless Applications

This repository contains the source code necessary to complete setup of the Securing Serverless Applications workshop and to run the workshop outside of an AWS event. 

## Table of Contents

1. [Running from an AWS Event](#running-from-an-aws-event)
2. [Running from your own account](#running-from-your-own-account)
3. [Complete Setup](#complete-setup)

## Running from an AWS Event

If running from an AWS event an account with the necessary prerequisites will be provisioned.  To complete setup for the event, make sure you are in the **Cloud9** environment provisioned for your AWS event account and then and continue to [Complete Setup](#complete-setup).

## Running from your own account
If you are running from your own account you must have access to a command line with the **AWS Command Line Interface** (AWS CLI) installed.  You can find instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for installing and configuring the AWS CLI.

1. Create the workshop stack by executing the following command at the command line in a terminal.
~~~
# Make sure you are at the project root
aws cloudformation create-stack --stack-name 'Secure-Serverless' --template-body file://setup/Secure-Serverless.yml
~~~
2. Continue to [Complete Setup](#complete-setup)

## Complete Setup
1. Open the Cloud9 environment created by CloudFormation template.  Execute the following command in a terminal window.
~~~
# Make sure you are at the project root
source setup/bootstrap.sh
~~~
2. You can now proceed following the workshop instructions.


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

