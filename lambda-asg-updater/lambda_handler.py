# lambda_function.py
import boto3, os, json
from datetime import datetime, timezone, timedelta


def lambda_handler(event, context):

    # Get values from Lambda environment variables.
    launch_template_id = os.environ["launch_template_id"]
    sns_arn = os.environ["sns_arn"]
    asg_name = os.environ["asg_name"]

    # Create boto3 clients
    ec2 = boto3.client("ec2")
    asg = boto3.client("autoscaling")
    sns = boto3.client("sns")

    # Parse the event to get the new image id
    print(event)
    new_ami = event["resources"][0]
    print(new_ami)

    def update_current_launch_template_ami(ami):
        response = ec2.create_launch_template_version(
            LaunchTemplateId=launch_template_id,
            SourceVersion="$Latest",
            VersionDescription="Latest-AMI",
            LaunchTemplateData={
                "ImageId": ami
            }
        )
        print(f"New launch template created with AMI {ami}")

    def set_launch_template_default_version():
        response = ec2.modify_launch_template(
            LaunchTemplateId=launch_template_id,
            DefaultVersion="$Latest"
        )
        print("Default launch template set to $Latest.")
        previous_version = str(
            int(response["LaunchTemplate"]["LatestVersionNumber"]) - 2)
        response = ec2.delete_launch_template_versions(
            LaunchTemplateId=launch_template_id,
            Versions=[
                previous_version,
            ]
        )
        print(f"Old launch template {previous_version} deleted.")

    def create_asg_scheduled_action(start_time, desired_capacity):
        response = asg.put_scheduled_update_group_action(
            AutoScalingGroupName=asg_name,
            ScheduledActionName=f"Desire {desired_capacity}",
            StartTime=start_time,
            DesiredCapacity=desired_capacity
        )
        print(f"""
            ASG action created
            Start time: {start_time}"
            Desired capacity: {desired_capacity}
            """)

    def send_sns_notification(subject, message):
        response = sns.publish(
            TargetArn=sns_arn,
            Message=message,
            Subject=subject,
        )
        print(f"""
            Notification email sent.
            Subject: {subject}
            Message: {message}
            """)

    def update_launch_template_and_asg():
        # Update template AMI and set as default
        update_current_launch_template_ami(new_ami)
        set_launch_template_default_version()

        # Create future ASG actions to roll out the new AMI
        now_utc = datetime.now(timezone.utc)
        in_01_min = now_utc + timedelta(minutes=1)
        in_6_min = now_utc + timedelta(minutes=6)
        create_asg_scheduled_action(in_01_min, 2)
        create_asg_scheduled_action(in_6_min, 1)

        # Send a notification that the update succeeded.
        subject = "AMI updated!"
        message = f"AMI updated! New AMI is {new_ami}."
        send_sns_notification(subject, message)
        return message

    ami_status = update_launch_template_and_asg()

    # Show if AMI was updated in CloudWatch log group.
    print(ami_status)

    # Show if AMI was updated in Lambda console.
    return ami_status