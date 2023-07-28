#!/usr/bin/env python3
import boto3
import json

iam = boto3.client('iam')

my_region = boto3.session.Session().region_name
my_account = boto3.client('sts').get_caller_identity()['Account']

def get_assume_role_policy(principals : list):
    def get_statement(principal : str):
        return {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    f"{principal}.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
            }
    return {
        "Version": "2012-10-17",
        "Statement": [ get_statement(ppl) for ppl in principals]
    }
    
codepipeline_policy_statements = [   
	{
		"Action": [
			"iam:PassRole"
		],
		"Resource": "*",
		"Effect": "Allow",
		"Condition": {
			"StringEqualsIfExists": {
				"iam:PassedToService": [
					"cloudformation.amazonaws.com",
					"elasticbeanstalk.amazonaws.com",
					"ec2.amazonaws.com",
					"ecs-tasks.amazonaws.com"
				]
			}
		}
    },
	{
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
    },
	{
		"Effect": "Allow",
		"Action": [
			"cloudformation:CreateStack",
			"cloudformation:DeleteStack",
			"cloudformation:DescribeStacks",
			"cloudformation:UpdateStack",
			"cloudformation:CreateChangeSet",
			"cloudformation:DeleteChangeSet",
			"cloudformation:DescribeChangeSet",
			"cloudformation:ExecuteChangeSet",
			"cloudformation:SetStackPolicy",
			"cloudformation:ValidateTemplate",
			"iam:PassRole"
		],
		"Resource": "*"
	},
	{
		"Action": [
			"codebuild:BatchGetBuilds",
			"codebuild:StartBuild",
			"codebuild:BatchGetBuildBatches",
			"codebuild:StartBuildBatch"
		],
		"Resource": "*",
		"Effect": "Allow"
    },
	{
		"Action": [
			"codedeploy:CreateDeployment",
			"codedeploy:GetApplication",
			"codedeploy:GetApplicationRevision",
			"codedeploy:GetDeployment",
			"codedeploy:GetDeploymentConfig",
			"codedeploy:RegisterApplicationRevision"
		],
		"Resource": "*",
		"Effect": "Allow"
	},	
	{
		"Action": [
			"elasticbeanstalk:*",
			"ec2:*",
			"elasticloadbalancing:*",
			"autoscaling:*",
			"cloudwatch:*",
			"s3:*",
			"sns:*",
			"cloudformation:*",
			"rds:*",
			"sqs:*",
			"ecs:*"
		],
		"Resource": "*",
		"Effect": "Allow"
	},
	{
		"Action": [
			"lambda:InvokeFunction",
			"lambda:ListFunctions"
		],
		"Resource": "*",
		"Effect": "Allow"
	},	
]    
    

def create_codepipeline_policy(policy_name : str,tags : list):
    code_policy_doc = json.dumps({
    "Version": "2012-10-17",
    "Statement": codepipeline_policy_statements
    })
    return iam.create_policy(PolicyName=f'{policy_name}-policy',
    Description=f'policies needed for the codepipeline project ',
    PolicyDocument=code_policy_doc,
    Tags=tags
    )
    
def create_codepipeline_role(role_name : str, tags : list):

    #Create a role to be used/assumed by codepipeline 
    role = iam.create_role(RoleName=role_name,
        AssumeRolePolicyDocument=json.dumps(get_assume_role_policy(['codepipeline','cloudformation'])),
        Tags=tags)

    #Create  necessary resource access policies and attach it to the role
    policy = create_codepipeline_policy(policy_name=f'{role_name}_policy',tags=tags)
        
    iam.attach_role_policy(PolicyArn=policy['Policy']['Arn'],
        RoleName=role_name)
     
    iam.attach_role_policy(PolicyArn='arn:aws:iam::aws:policy/AWSLambda_FullAccess',
    	RoleName=role_name)
    return role

codepipeline_role = create_codepipeline_role(role_name='role-codepipeline-project3-search-domain',
tags=[{'Key': 'project-name','Value': 'project3-search-domain'}])
print(codepipeline_role)
    