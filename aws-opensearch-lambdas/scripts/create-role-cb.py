#!/usr/bin/env python3
import boto3
import json

iam = boto3.client('iam')

my_region = boto3.session.Session().region_name
my_account = boto3.client('sts').get_caller_identity()['Account']

def get_assume_role_policy(principal : str):
    return {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    f"{principal}.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
    
def get_cloudwatch_policy_statement():
    return  {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        }
        
def get_s3_artifact_policy_statement()        :
    return {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:CreateBucket",
                "s3:GetBucketAcl",
                "s3:List*",
                "s3:GetBucketLocation"
            ]
        }    

def get_codecommit_policy_statement():
    return    {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "codecommit:GitPull"
            ]
        }
        
def get_report_group_policy_statement():
    return    {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": "*"
        }

def create_codebuild_policy(policy_name : str,tags : list):
    code_policy_doc = json.dumps({
    "Version": "2012-10-17",
    "Statement": [
        get_cloudwatch_policy_statement(),
        get_s3_artifact_policy_statement(),
        get_codecommit_policy_statement(),
        get_report_group_policy_statement()
        ]
    })
    return iam.create_policy(PolicyName=f'{policy_name}-policy',
    Description=f'policies needed for the code build project ',
    PolicyDocument=code_policy_doc,
    Tags=tags
    )
    
def create_codebuild_role(role_name : str, tags : list):

    #Create a role to be used/assumed by codebuild 
    role = iam.create_role(RoleName=role_name,
        AssumeRolePolicyDocument=json.dumps(get_assume_role_policy('codebuild')),
        Tags=tags)

    #Create  necessary resource access policies and attach it to the role
    policy = create_codebuild_policy(policy_name=f'{role_name}_policy',tags=tags)
        
    
    iam.attach_role_policy(PolicyArn=policy['Policy']['Arn'],
        RoleName=role_name)
    return role

cb_role = create_codebuild_role(role_name='cb-role-project3-search-domain',
tags=[{'Key': 'project-name','Value': 'project3-search-domain'}])
print(cb_role)
    