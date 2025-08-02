#!/bin/bash
ArtifactDir=artifacts/input
Action=apply
HomeDir="$PWD"

while getopts "uds:t:c:g:n:" opt
do
  case $opt in
    d)
      read -p "Destroy?  " destroy 
      echo "Make sure you empty the S3 bucket!!!"
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
  esac
done

shift $((OPTIND - 1))

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
if ! test -z "$destroy" 
then
  if [ "${destroy,,}" == "yes" ]
  then 
    Action=destroy
  fi
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

echo "Creating the build parameters"
sed -e "s/subnet-xxxx/$build_subnet_id/g" -e "s/sg-xxxx/$build_security_group_id/g" $ArtifactDir/terraform/terraform.tfvars.template > $ArtifactDir/terraform/terraform.tfvars

echo "Initializing cicd terraform environment..."
cd pipeline
export AWS_PROFILE=$cicd_profile
terraform init

echo "Deploying CiCd pipeline..."
terraform $Action -var "target_account=$target_acct_no" -auto-approve -input=false


echo "Initializing target account terraform environment..."
cd $HomeDir
cd target-account
export AWS_PROFILE=$target_acct_profile
terraform init

echo "Deploying resources in the target account..."
terraform $Action -var "cicd_account=$cicd_acct_no" -auto-approve -input=false




