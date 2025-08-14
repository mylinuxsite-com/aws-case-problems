#!/usr/bin/env python3
import os

import aws_cdk as cdk

from abac_sample_1.abac_sample_1_stack import AbacSample1Stack

app     = cdk.App()
region  = os.environ.get('CDK_DEFAULT_REGION')
account = os.environ.get('CDK_DEFAULT_ACCOUNT')

step_no   = app.node.try_get_context("step_no")
stack_params = app.node.try_get_context("stack_params")

AbacSample1Stack(app, "AbacSample1Stack",
    env=cdk.Environment(region=region,account=account),
    stack_params=stack_params,step_no=step_no            
)

app.synth()
