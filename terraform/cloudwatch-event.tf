resource "aws_cloudwatch_event_rule" "new_ami" {
  name        = "capture-new-ami"
  description = "Capture each new AMI event"

  event_pattern = <<EOF
{
  "detail-type": [
    "AmiBuilder"
  ],
  "source": [
    "com.ami.builder"
  ],
  "detail": {
    "AmiStatus": [
      "Created"
    ]
  }
}
EOF
}


resource "aws_cloudwatch_event_target" "sns_topic" {  
  rule      = aws_cloudwatch_event_rule.new_ami.name
  arn       = "arn:aws:lambda:${var.region}:${var.account_id}:function:UpdateASG"
}
