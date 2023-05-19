## Securing Serverless Applications

This repository contains the source code necessary to complete setup of the Securing Serverless Applications workshop and to run the workshop outside of an AWS event.  

**Prerequisites:** requires access to a command line and  aws cli installed.

1. If you are running the workshop in an AWS event continue to [CompleteSetup](#complete-setup)
2. If you are running the workshop outside of an AWS event, create the stack by executing the following command at the command line in a terminal.
~~~
aws cloudformation create-stack --stack-name 'Secure-Serverless' --template-body file://setup/Secure-Serverless.yml
~~~
3. Continue to [Complete Setup](#complete-setup)

## Complete Setup
1. Open the Cloud9 environment created by CloudFormation template.  Execute the following command in a terminal window.
~~~
source setup/bootstrap.sh
~~~
2. You can now proceed following the workshop instructions.


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

