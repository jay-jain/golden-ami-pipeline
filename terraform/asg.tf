# # See: https://engineering.redislabs.com/posts/aws-autoscaling-groups-with-terraform/ 

# #Get current launch template if it exists
# data "aws_launch_template" "current" {
#   filter {
#     name   = "launch-template-name"
#     values = ["${var.application}"]
#   }
# }

# # Gets autoscaling groups that use the launch template's latest version 
# data "aws_autoscaling_groups" "current" {
#   filter {
#     name   = "key"
#     values = ["${var.application}-template-version"]
#   }
#   filter {
#     name   = "value"
#     values = ["${coalesce(data.aws_launch_template.current.latest_version, 0)}"]
#   }
# }

# # Get info on latest auto scaling group
# data "aws_autoscaling_group" "current" {
#   count = length(data.aws_autoscaling_groups.current.names)
#   name  = data.aws_autoscaling_groups.current.names[count.index]
# }

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.application}-ASG"
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies      = ["OldestInstance"]
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
  min_size = 1
  max_size = 2
  desired_capacity = 1
  availability_zones = var.availability_zones

  #desired_capacity = length(data.aws_autoscaling_groups.current.names) > 0 ? data.aws_autoscaling_group.current[0].desired_capacity : 1

  tag {
    key                 = "${var.application}-template-version"
    value               = aws_launch_template.launch_template.latest_version
    propagate_at_launch = true
  }

  # lifecycle {
  #   create_before_destroy = true
  # }
  depends_on = [aws_launch_template.launch_template]
}

resource "aws_launch_template" "launch_template" {
  name                                 = "${var.application}"
  image_id                             = var.base_ami # Default Ubuntu Server 20.04 AMI provided by AWS
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name          = "${var.application}"
    }
  }
  update_default_version = true  
}