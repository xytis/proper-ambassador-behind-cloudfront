import boto3
import logging
import os
import json

NAME = os.getenv( 'PREFIX_NAME', "AUTOUPDATE")
VPC_ID = os.getenv( 'VPC_ID',"")
REGION = os.getenv( 'REGION',"us-east-1")
CLUSTER_NAME = os.getenv( 'CLUSTER_NAME', "" )


def lambda_handler(event, context):
    if CLUSTER_NAME == "":
        return

    # Set the environment variable DEBUG to 'true' if you want verbose debug details in CloudWatch Logs.
    try:
        if os.environ['DEBUG'] == 'true':
            logging.getLogger().setLevel(logging.INFO)
    except KeyError:
        pass

    #Creating ec2 boto3 client
    client = boto3.client('ec2',region_name=REGION)
    ag_client = boto3.client('autoscaling', region_name=REGION)

    ec2 = boto3.resource('ec2')
    eks_client = boto3.client('eks')

    ags = get_cluster_autoscaling_groups(eks_client)
    cf_sg_ids = get_security_groups(client) # get cloudfront security groups
    target_ids = get_target_instances(ag_client, ags)

    for id in target_ids:
      instance = ec2.Instance(id)
      nis = instance.network_interfaces
      for ni in nis: # apply change to each network interface
        old_sg_ids = [sg['GroupId'] for sg in ni.groups]
        new_sg_ids = list(set(old_sg_ids) | set(cf_sg_ids))

        old_sg_ids.sort()
        new_sg_ids.sort()
        if old_sg_ids != new_sg_ids:
            logging.info("Updating security groups for instance " + instance.instance_id + " and interface " + ni.network_interface_id + ". New security group list is: " + ','.join(new_sg_ids))
            ni.modify_attribute(
                Groups=new_sg_ids
            )
        else:
            logging.info("No need to update security groups for instance " + instance.instance_id + " and interface " + ni.network_interface_id )


def get_cluster_autoscaling_groups(client):
    response = client.list_nodegroups(
        clusterName=CLUSTER_NAME
    )

    ags = []
    for ng in response['nodegroups']:
        response = client.describe_nodegroup(
            clusterName=CLUSTER_NAME,
            nodegroupName=ng
        )
        ags = ags + [a['name'] for a in response['nodegroup']['resources']['autoScalingGroups']]
    return ags


def get_target_instances(client, ags):
    response = client.describe_auto_scaling_groups(
        AutoScalingGroupNames= ags
    )

    ids = []
    for ag in response['AutoScalingGroups']:
        ag_ids = [instance['InstanceId'] for instance in ag['Instances']]
        ids = list(set(ids) | set(ag_ids))

    return ids

def get_security_groups(client):
    filters = [
                { 'Name': "tag-key", 'Values': ['PREFIX_NAME'] },
                { 'Name': "tag-value", 'Values': [NAME] },
                { 'Name': "vpc-id", 'Values': [VPC_ID] }
            ]

    #Extracting specific security groups with tags 
    response = client.describe_security_groups(Filters=filters)

    group_ids = [gr['GroupId'] for gr in response['SecurityGroups']]
    return group_ids

# lambda_handler("a", "b")
