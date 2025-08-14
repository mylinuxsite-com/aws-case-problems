import os
import boto3
from aws_cdk import (
    Stack,
    Aws,
    Tags,
    CfnOutput,
    custom_resources as cr,
    aws_iam as iam,
    aws_s3  as s3,
    aws_s3_deployment as s3_deployment
)
from constructs import Construct

INPUT_TEST_FILE="hello_world.txt"

sts_client = boto3.client("sts")
s3_client  = boto3.client('s3')

class AbacSample1Stack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, env=kwargs['env'])

        stack_params = kwargs['stack_params']
        step_no      = kwargs['step_no']
        tags         = stack_params[step_no]["tags"]
        acct_no      = kwargs["env"].account

        self.create_roles_and_policies(stack_params["iam_roles"],acct_no,tags)
        self.create_s3_and_assets(tags)

    def create_roles_and_policies(self, iam_roles,acct_no,tags):
        role_map = {}
        for name, trust_and_policy in iam_roles.items():
            assumed_by_name = trust_and_policy['assumed_by']
            if assumed_by_name in role_map:
                assumed_role_arn = role_map[assumed_by_name].role_arn
            else:
                if assumed_by_name == "{caller-identity}":
                    sts_response = sts_client.get_caller_identity()
                    assumed_role_arn = sts_response['Arn']
                    assumed_by_name = assumed_role_arn.split("/")[1]
                
                if assumed_by_name == "root":
                    assumed_role_arn = f'arn:aws:iam::{Aws.ACCOUNT_ID}:root'
                else:
                    assumed_role_arn = iam.Role.from_lookup(
                        self,f'{name}TrustedRole',
                        role_name=assumed_by_name
                    ).role_arn

            role_conditions = trust_and_policy["conditions"] if "conditions" in trust_and_policy else {}
            role = iam.Role(self,name,
                        assumed_by=iam.PrincipalWithConditions(iam.ArnPrincipal(assumed_role_arn),
                            role_conditions),
                        role_name=name
            )

            if name in tags and tags[name]:
                for k,v in tags[name].items():
                    Tags.of(role).add(k,v)

            if "policy" in trust_and_policy:
                role_policy = trust_and_policy["policy"]
                policy_document = iam.PolicyStatement(
                    actions=role_policy["actions"],
                    conditions=role_policy["conditions"],
                    resources=role_policy["resources"],
                    effect=iam.Effect.ALLOW,
                    sid="sid1"
                )
                managed_policy = iam.ManagedPolicy(self,f'{name}-policy',
                        managed_policy_name=f'{name}-policy',
                        statements=[policy_document]
                )

                role.add_managed_policy(managed_policy)

            role_map[name] = role
        

    def create_s3_and_assets(self,tags):
        bucket = s3.Bucket(self, "Bucket",
                    block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
                    encryption=s3.BucketEncryption.S3_MANAGED,
                    enforce_ssl=True,
                    versioned=True
                )

        deployment = s3_deployment.BucketDeployment(self, "TestFile",
                        sources=[s3_deployment.Source.asset(os.path.join(os.getcwd(),"input"))],
                        destination_bucket=bucket
                )

        CfnOutput(self,"s3-bucket-name",value=bucket.bucket_name)

        if "s3_bucket" in tags and tags["s3_bucket"]:
            tagset = []
            for k,v in tags["s3_bucket"].items():
                tagset.append({"Key":k,"Value":v})

            s3_object_tags = cr.AwsCustomResource(self, "AddS3ObjectTags",
                on_create=cr.AwsSdkCall( 
                    service="S3",
                    action="PutObjectTagging",
                    parameters={
                        "Bucket":bucket.bucket_name,
                        "Key": INPUT_TEST_FILE,
                        "Tagging": {"TagSet":tagset}
                    },                
                    physical_resource_id=cr.PhysicalResourceId.of("id")
                ),
                policy=cr.AwsCustomResourcePolicy.from_statements(
                    [iam.PolicyStatement(
                        actions= ["s3:PutObjectTagging","s3:DeleteObjectTagging"],
                        effect =iam.Effect.ALLOW,
                        resources=["*"]
                    )]
                )                
            )        

            # for k,v in tags["s3_bucket"].items():
            #     s3_client.put_object_tagging(
            #         Bucket=bucket.bucket_name,
            #         Key=INPUT_TEST_FILE,
            #         Tagging={k:v}
            # )
