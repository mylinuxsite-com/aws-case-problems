#!/bin/bash
ArtifactDir=artifacts/input
Action=create-stack

while getopts "uds:t:c:g:n:" opt
do
  case $opt in
    d)
      read -p "Delete stacks?  " delete_stack 
      echo "Make sure you empty the S3 bucket!!!"
      ;;
    s)
      stack_name="$OPTARG"
      echo "Stack Name set to: $stack_name"
      ;;
    t)
      target_acct_profile="$OPTARG"
      echo "Target profile set to: $target_acct_profile"
      ;;
    c)
      cicd_profile="$OPTARG"
      echo "CiCd profile set to: $cicd_profile"
      ;;
    n)
      build_subnet_id="$OPTARG"
      echo "The build subnet id set to: $build_subnet_id"
      ;;
    g)
      build_security_group_id="$OPTARG"
      echo "The build security group id set to: $build_security_group_id"
      ;;            
    u)
      Action=update-stack
      echo "Updating stacks..."
      ;;

  esac
done

shift $((OPTIND - 1))

if [ ! "$stack_name" ]
then
   echo "Missing Stack Name (-s)"
   exit 1
fi

if [ ! "$target_acct_profile" ]
then
   echo "Missing Target Account profile. (-t)"
   exit 1
fi
if [ ! "$cicd_profile" ]
then
   echo "Missing CiCd profile. (-c)"
   exit 1
fi

if ! test -z "$delete_stack" 
then
  if [ "${delete_stack,,}" == "yes" ]
  then 
    echo "Deleting stacks..."
    aws cloudformation delete-stack --stack-name $stack_name --profile $target_acct_profile
    aws cloudformation delete-stack --stack-name $stack_name --profile $cicd_profile
  else
    echo "Deleting (-d) not confirmed. Doing nothing!"
  fi
  exit
fi

if [ ! "$build_subnet_id" ]
then
   echo "Missing the build subnet id (-n)"
   exit 1
fi
if [ ! "$build_security_group_id" ]
then
   echo "Missing the build security group id (-g)"
   exit 1
fi


cicd_acct_no=$(aws sts get-caller-identity --profile $cicd_profile --query "Account" --output text)
if [ $? -ne 0 ]
then
   echo "Error identifying CiCd acct no. !"
   exit 1
else
   echo "CiCd acct no. set to: $cicd_acct_no"
fi

target_acct_no=$(aws sts get-caller-identity --profile $target_acct_profile --query "Account" --output text)
if [ $? -ne 0 ]
then
   echo "Error identifying target acct no. !"
   exit 1
else
   echo "Target acct no. set to: $target_acct_no"
fi

echo "Deploying CiCd pipeline template..."
aws cloudformation $Action --stack-name $stack_name \
--template-body file://pipeline/template.yaml \
--capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" "CAPABILITY_AUTO_EXPAND" \
--parameters ParameterKey=TargetAccount,ParameterValue=$target_acct_no \
--profile $cicd_profile

echo "Awaiting for the stacks creation/update to complete..." 
if [ "$Action" == "create-stack" ] 
then 
   aws cloudformation wait stack-create-complete --stack-name $stack_name --profile $cicd_profile
else
   aws cloudformation wait stack-update-complete --stack-name $stack_name --profile $cicd_profile
fi

s3_cicd_bucket=$(aws cloudformation describe-stacks --profile $cicd_profile --stack-name $stack_name  --query "Stacks[0].Outputs[?OutputKey=='S3CiCdBucket'].OutputValue" --output text)
input_artifact=$(aws cloudformation describe-stacks --profile $cicd_profile --stack-name $stack_name --query "Stacks[0].Outputs[?OutputKey=='InputArtifact'].OutputValue" --output text)

echo "Creating the build parameters"
sed -e "s/subnet-xxxx/$build_subnet_id/g" -e "s/sg-xxxx/$build_security_group_id/g" $ArtifactDir/parameters.template > $ArtifactDir/parameters.json

echo "Uploading the input artifact $input_artifact to $s3_cicd_bucket S3"

input_artifact_zip=/tmp/$input_artifact

zip -r $input_artifact_zip $ArtifactDir
aws s3 cp $input_artifact_zip s3://$s3_cicd_bucket --profile $cicd_profile

echo "Deploying target account pipeline template..."
aws cloudformation $Action --stack-name $stack_name \
--template-body file://target-account/template.yaml \
--capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" "CAPABILITY_AUTO_EXPAND" \
--parameters ParameterKey=CiCdAccount,ParameterValue=$cicd_acct_no ParameterKey=CiCdPipelineName,ParameterValue=$stack_name ParameterKey=CiCdBucketName,ParameterValue=$s3_cicd_bucket  \
--profile $target_acct_profile



