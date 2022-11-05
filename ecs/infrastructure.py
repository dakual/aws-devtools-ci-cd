import boto3, json
from json import JSONEncoder
import datetime

AWS_REGION   = "eu-central-1"
cluster_name = "devtools-demo"
app_name     = "DemoApp"
image        = "632296647497.dkr.ecr.eu-central-1.amazonaws.com/demo-app"
subnets      = ["subnet-02caf3f4a7dab08f6", "subnet-0e00855f4313be466", "subnet-0535e60978084785d"]
security_groups = ["sg-095938d5e717361ea"]
LOG_GROUP    = "/ecs/" + app_name + "Logs"

class DateTimeEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime.date, datetime.datetime)):
            return obj.isoformat()

# Create log group
client = boto3.client('logs', region_name=AWS_REGION)
response = client.create_log_group(
    logGroupName=LOG_GROUP,
)
print(json.dumps(response, indent=4, cls=DateTimeEncoder))


# Create ECS Cluster
client   = boto3.client("ecs", region_name=AWS_REGION)
response = client.create_cluster(clusterName=cluster_name)
print(json.dumps(response, indent=4, cls=DateTimeEncoder))

# Create ECS Task Defination
response = client.register_task_definition(
    containerDefinitions=[
        {
            "name": app_name + "Container",
            "image": image,
            "portMappings": [
                {
                    "containerPort": 8080,
                    "hostPort": 8080,
                    "protocol": "tcp"
                }
            ],
            "essential": True,
            "environment": [
                {
                    "name": "ENV_MESSAGE",
                    "value": "Demo uygulama"
                }
            ],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": LOG_GROUP,
                    "awslogs-region": AWS_REGION,
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ],
    executionRoleArn="arn:aws:iam::632296647497:role/ecsTaskExecutionRole",
    family=app_name,
    networkMode="awsvpc",
    requiresCompatibilities= [
        "FARGATE"
    ],
    cpu= "256",
    memory= "512"
)

print(json.dumps(response, indent=4, cls=DateTimeEncoder))


# Create ECS Service
response = client.create_service(cluster=cluster_name, 
    serviceName=app_name + "Service",
    taskDefinition=app_name,
    desiredCount=1,
    networkConfiguration={
        'awsvpcConfiguration': {
            'subnets': subnets,
            'assignPublicIp': 'ENABLED',
            'securityGroups': security_groups
        }
    },
    launchType='FARGATE',
)
print(json.dumps(response, indent=4, cls=DateTimeEncoder))
