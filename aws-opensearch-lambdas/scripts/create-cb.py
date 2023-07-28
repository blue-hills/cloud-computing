#!/usr/bin/env python3
import boto3

client_codebuild = boto3.client('codebuild')

def create_codebuild_project(name : str, desc : str, repo_url : str , artifact_bucket : str, service_role : str,
    tags : list):
    ''' name: CodeBulid Project
        repo_url: Source Git Repository
        artifact_bucket: S3 bucket to store the Codebuild artifacts
        service_role: to grant necessary permissions to codebuild service 
    '''

    source={
            'type': 'CODECOMMIT',
            'location': repo_url,
            'gitCloneDepth': 0,
            'gitSubmodulesConfig': {
                'fetchSubmodules': True
            },
            'buildspec': ''
        }
    
    artifacts={
            'type': 'S3',
            'location': artifact_bucket,
            'path': '',
            'namespaceType': 'NONE',
            'name': '',
            'packaging': 'NONE',
            'overrideArtifactName': True,
            'encryptionDisabled': True,
            'artifactIdentifier': '',
            'bucketOwnerAccess': 'NONE' 
        }
        
    environment={
            'type': 'LINUX_CONTAINER',
            'image': 'aws/codebuild/standard:4.0',
            'computeType': 'BUILD_GENERAL1_SMALL',
        }    
    
    return client_codebuild.create_project(
        name=name,
        description=desc,
        source=source, 
        environment=environment,
        artifacts=artifacts,
        serviceRole=service_role,
        tags=tags)
    

#S3 bucket to store all codebuild project artifacts
artifact_bucket = 'search-domain-project-artifacts'
#Service role for the codebuild project to allow S3 /CodeCommit/LogGroup/Report actions
service_role = 'arn:aws:iam::506160996768:role/cb-role-project3-search-domain'
tags = [{'key': 'project-name','value': 'search-domain'}]


def create_codebuild_project_pdftext_lambda():
    return create_codebuild_project(name = 'cb-pdftext-lambda',
        desc='To build artifacts for installing python lambda to convert pdf documents stored in S3 buckets to text',
        repo_url='https://git-codecommit.us-east-1.amazonaws.com/v1/repos/pdf-to-text',
        artifact_bucket=artifact_bucket,
        service_role=service_role,
        tags=tags)
        
def create_codebuild_project_upload_lambda():
    return create_codebuild_project(name = 'cb-upload-lambda',
        desc='To build artifacts for installing python lambda to upload documents to search domain',
        repo_url='https://git-codecommit.us-east-1.amazonaws.com/v1/repos/upload-to-search',
        artifact_bucket=artifact_bucket,
        service_role=service_role,
        tags=tags)        

def create_codebuild_project_search_lambda():
    return create_codebuild_project(name = 'cb-search-lambda',
        desc='To build artifacts for installing python lambda to query the search-domain-gateway',
        repo_url='https://git-codecommit.us-east-1.amazonaws.com/v1/repos/search-gateway',
        artifact_bucket=artifact_bucket,
        service_role=service_role,
        tags=tags)


print(create_codebuild_project_pdftext_lambda())
print(create_codebuild_project_upload_lambda())
print(create_codebuild_project_search_lambda())

