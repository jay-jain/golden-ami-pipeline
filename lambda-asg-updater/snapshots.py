"""
Code adapted from and inspired by http://blog.ranman.org/cleaning-up-aws-with-boto3/.
https://gist.github.com/luhn/802f33ce763452b7c3b32bb594e0d54d
"""
import os
import re
from datetime import datetime, timedelta
import boto3


ACCOUNT_ID = 'XXXXXXXXXXXXXXXXXX'


def lambda_handler(event, context):
    ec2 = boto3.resource("ec2")

    # Gather AMIs and figure out which ones to delete
    my_images = ec2.images.filter(Owners=[ACCOUNT_ID])
    print(my_images)

    # Don't delete images in use
    used_images = {
        instance.image_id for instance in ec2.instances.all()
    }
    print(used_images)

    # Keep everything younger than two weeks
    young_images = set()
    for image in my_images:
        created_at = datetime.strptime(
            image.creation_date,
            "%Y-%m-%dT%H:%M:%S.000Z",
        )
        if created_at > datetime.now() - timedelta(0):
            young_images.add(image.id)
    print("Young images: ",young_images)
    # Keep latest one
    latest = dict()
    for image in my_images:
        split = image.name.split('-')
        try:
            timestamp = int(split[-1])
        except ValueError:
            continue
        name = '-'.join(split[:-1])
        if(
                name not in latest
                or timestamp > latest[name][0]
        ):
            latest[name] = (timestamp, image)
    latest_images = {image.id for (_, image) in latest.values()}
    print("Latest Images: ", latest_images)
    # Delete everything
    safe = used_images | young_images | latest_images
    for image in (
        image for image in my_images if image.id not in safe
    ):
        print('Deregistering {} ({})'.format(image.name, image.id))
        image.deregister()
    print("Safe Images: ",safe)
    # Delete unattached snapshots
    print('Deleting snapshots.')
    images = [image.id for image in ec2.images.all()]
    for snapshot in ec2.snapshots.filter(OwnerIds=[ACCOUNT_ID]):
        print('Checking {}'.format(snapshot.id))
        r = re.match(r".*for (ami-.*) from.*", snapshot.description)
        if r:
            if r.groups()[0] not in images:
                print('Deleting {}'.format(snapshot.id))
                snapshot.delete()
