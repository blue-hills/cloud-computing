#!/usr/bin/env python3

import boto3


codepipeline_client = boto3.client('codepipeline')
codecommit_client = boto3.client('codecommit')
codebuild_client = boto3.client('codebuild')

region = boto3.session.Session().region_name
account = boto3.client('sts').get_caller_identity()['Account']


def does_repo_exist(repo_name : str):
    repos = codecommit_client.list_repositories()['repositories']
    return any(item['repositoryName'] == repo_name for item in repos)

def does_codebuildproject_exist(proj_name : str):
    projects = codebuild_client.list_projects()['projects']
    return any(item == proj_name for item in projects)
    
def does_pipeline_exist(pipeline_name : str):
    avail_pipelines = codepipeline_client.list_pipelines()['pipelines']
    return any(item['name']==pipeline_name for item in avail_pipelines)    
    
    
def create_4_stage_pipeline(prefix : str, #prefix for stage names
    pipeline_name : str,pipeline_role : str,pipeline_artifact : str, #pipeline details
    source_repo_name : str, #codecommit -- Source stage
    codebuild_project_name : str, #codebuild - Build stage
    sns_arn : str, #sns for approval stage
    stack_name : str, stack_template_file : str,#stack name and template file for cloudformation deployment
    tags : list): #tags 
    
    if not does_codebuildproject_exist(codebuild_project_name):
        raise RuntimeError(f'Code bulid project {codebuild_project_name} does not exist')
        
    if not does_repo_exist(source_repo_name):
        raise RuntimeError(f'CodeCommit Repo {source_repo_name} does not exist')

    source_stage = {
                "name": f"{prefix}Source",
                "actions": [
                    {
                        "name": "Source",
                        "actionTypeId": {
                            "category": "Source",
                            "owner": "AWS",
                            "provider": "CodeCommit",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {
                            "BranchName": "master",
                            "OutputArtifactFormat": "CODE_ZIP",
                            "PollForSourceChanges": "false",
                            "RepositoryName": source_repo_name
                        },
                        "outputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "inputArtifacts": [],
                        "region": region,
                        "namespace": "SourceVariables"
                    }
                ]
            }
            
    build_stage =   {
                "name": f"{prefix}Build",
                "actions": [
                    {
                        "name": "Build",
                        "actionTypeId": {
                            "category": "Build",
                            "owner": "AWS",
                            "provider": "CodeBuild",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {
                            "ProjectName": codebuild_project_name
                        },
                        "outputArtifacts": [
                            {
                                "name": "BuildArtifact"
                            }
                        ],
                        "inputArtifacts": [
                            {
                                "name": "SourceArtifact"
                            }
                        ],
                        "region": region,
                        "namespace": "BuildVariables"
                    }
                ]
            }
            
    approval_stage =             {
                "name": f"{prefix}Approval",
                "actions": [
                    {
                        "name": "Approval",
                        "actionTypeId": {
                            "category": "Approval",
                            "owner": "AWS",
                            "provider": "Manual",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {
                            "NotificationArn": sns_arn
                        },
                        "outputArtifacts": [],
                        "inputArtifacts": [],
                        "region": region
                    }
                ]
            }
            
    deploy_stage =             {
                "name": f"{prefix}DeployStack",
                "actions": [
                    {
                        "name": "DeployStack",
                        "actionTypeId": {
                            "category": "Deploy",
                            "owner": "AWS",
                            "provider": "CloudFormation",
                            "version": "1"
                        },
                        "runOrder": 1,
                        "configuration": {
                            "ActionMode": "CREATE_UPDATE",
                            "Capabilities": "CAPABILITY_IAM,CAPABILITY_AUTO_EXPAND",
                            "RoleArn": pipeline_role,
                            "StackName": stack_name,
                            "TemplatePath": f"BuildArtifact::{stack_template_file}"
                        },
                        "outputArtifacts": [],
                        "inputArtifacts": [
                            {
                                "name": "BuildArtifact"
                            }
                        ],
                        "region": region
                    }
                ]
            }
            

    pipeline = {
        "name": pipeline_name,
        "roleArn": pipeline_role,
        "artifactStore": {
            "type": "S3",
            "location": pipeline_artifact
        },
        "stages": [ 
            source_stage ,
            build_stage ,
            approval_stage,
            deploy_stage,
        ],
        "version": 1
    }
    
    if does_pipeline_exist(pipeline_name):
        return codepipeline_client.update_pipeline(pipeline=pipeline)
    return codepipeline_client.create_pipeline(pipeline=pipeline,tags=tags)
  
pipeline_role = "arn:aws:iam::506160996768:role/role-codepipeline-project3-search-domain"
pipeline_artifact = "search-domain-project-artifacts"
sns_arn = "arn:aws:sns:us-east-1:506160996768:BuildStatus"
tags=[{'key': 'project-name','value': 'project3-search-domain'}]

def create_pipeline_search_lambda():
    return create_4_stage_pipeline(prefix="SearchLambda",
        pipeline_name='pipeline-search-lambda',
        pipeline_role=pipeline_role,
        pipeline_artifact=pipeline_artifact,
        source_repo_name="search-gateway",
        codebuild_project_name="cb-search-lambda",
        sns_arn=sns_arn,
        stack_name="stack-search-lambda",
        stack_template_file=f"search-gateway-output.yaml",
        tags=tags)

def create_pipeline_upload_lambda():
    return create_4_stage_pipeline(prefix="UploadLambda",
        pipeline_name='pipeline-upload-lambda',
        pipeline_role=pipeline_role,
        pipeline_artifact=pipeline_artifact,
        source_repo_name="upload-to-search",
        codebuild_project_name="cb-upload-lambda",
        sns_arn=sns_arn,
        stack_name="stack-upload-lamda",
        stack_template_file="upload-to-search-output.yaml",
        tags=tags)        

def create_pipeline_pdftext_lambda():
    return create_4_stage_pipeline(prefix="PdftextLambda",
        pipeline_name='pipeline-pdftext-lambda',
        pipeline_role=pipeline_role,
        pipeline_artifact=pipeline_artifact,
        source_repo_name="pdf-to-text",
        codebuild_project_name="cb-pdftext-lambda",
        sns_arn=sns_arn,
        stack_name="stack-pdftext-lamda",
        stack_template_file="pdf-to-text-output.yaml",
        tags=tags)  

print(create_pipeline_pdftext_lambda())
print(create_pipeline_upload_lambda())
print(create_pipeline_search_lambda())