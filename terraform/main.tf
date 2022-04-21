terraform {
  backend "s3" {
    bucket         = "tf-cloud-security-2022"
    key            = "cloud-security-2022/terraform.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "vpc_app" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = "true"

  tags = {
    Name = "flask-api-vpc"
  }
}

resource "aws_eip" "nat_gw_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_gw_ip.id
  subnet_id     = aws_subnet.public_az1.id
}

resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.vpc_app.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private az1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.vpc_app.id
  cidr_block              = var.private_subnet_az2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private az2"
  }
}

resource "aws_subnet" "private_az3" {
  vpc_id                  = aws_vpc.vpc_app.id
  cidr_block              = var.private_subnet_az3_cidr
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = false

  tags = {
    Name = "private az3"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc_app.id

  tags = {
    Name = "Private route table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az3" {
  subnet_id      = aws_subnet.private_az3.id
  route_table_id = aws_route_table.private.id
}

resource "aws_internet_gateway" "vpc_app" {
  vpc_id = aws_vpc.vpc_app.id
}

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.vpc_app.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.vpc_app.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public az2"
  }
}

resource "aws_subnet" "public_az3" {
  vpc_id                  = aws_vpc.vpc_app.id
  cidr_block              = var.public_subnet_az3_cidr
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public az3"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_app.id
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az3" {
  subnet_id      = aws_subnet.public_az3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app-web" {
  name        = "flask-api"
  description = "flask-api-app-web"
  vpc_id      = "${aws_vpc.vpc_app.id}"

  ingress {
    from_port   = "${var.app_port}"
    to_port     = "${var.app_port}"
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.vpc_app.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_web" {
  name        = "flask-api-elb"
  description = "flask-api-elb"
  vpc_id      = "${aws_vpc.vpc_app.id}"

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "elb_app" {
  name            = "flask-api"
  subnets         = ["${aws_subnet.public_az1.id}", "${aws_subnet.public_az2.id}", "${aws_subnet.public_az3.id}"]
  security_groups = ["${aws_security_group.elb_web.id}"]

  listener {
    instance_port     = "${var.app_port}"
    instance_protocol = "http"
    lb_port           = "${var.app_port}"
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:${var.app_port}/api/kubernetes"
    interval            = 5
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 5
  connection_draining         = true
  connection_draining_timeout = 60
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "lc_web_app" {
  lifecycle {
    create_before_destroy = true
  }

  image_id        = "${data.aws_ami.ubuntu_ami.id}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.app-web.id}"]
  user_data       = <<EOF
#cloud-config
repo_update: true
repo_upgrade: all

write_files:
  - content: |
      ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAyZjT0WieumgOoOJgOboJCgPzGUpXRHPfQ3fMAqsq/M3EM1u32NTUDRHporF46shXm4sz4CDXIltNOk08SUcnDwPnTIU+x8nsDnDOE4OaGBThmXa1vATR2/EANmESH5Y1mfYdxr0fUdvb8q93gGx/tMyAe7H6Y6PVoYXh9uUxMZ8o9vjleT875T+AtILBdLdJ/K1pHCqa6+xF6sTUnbyyY4qrkbiYuDIKj3F7DJ3hgKeeNT00XRpGIbuAKEZpMjsnV8TMYT2swJF6jMSQpy5ZYqtogsCmqt1TwPJ0TSejb9knC+zq3wRHigBYS2wvOaZ/nNjG3/Db60U+2w6TM1VGLtFooz2BnaQe9G8JgT0GuCVguMsiYoEBXrDAn+mQ8iEXZQfDes+hoxUsAFN8zAtqqR70A4tlAqUWT+zI4WXOn612IXdLo+v5R/E+E7qgwlvfM5J7ybT5Kx+eUq11yqinfVc6NhWErHNqCtmScRhJHrzwVOFBI+IUr6ZklhB5p4gM/qvb5vfWhS7bi439ihSpBVdU3BxcuP8XMlelr/nC7hB4V05Tdc4RfQ4NzKaxwwFFZwLhBn4ANxurtZIkX3IUn+aj0b3BLQeB5SLZWai04H89R4Q9/21f0007ZBFTsGm1qitAtBJI9miOWT7VGj3SCG4hXBwUKO8IvNPkMjrr1Q== cloud-security
    path: /home/ubuntu/ssh/authorized_keys
  - content: |
      <VirtualHost *:80>
        ServerAdmin webmaster@cloud-security.jbc.dev
        ServerName www.cloud-security.jbc.dev
        ServerAlias cloud-security.jbc.dev
        ErrorLog /var/www/cloud-security.jbc.dev/logs/error.log
        CustomLog /var/www/cloud-security.jbc.dev/logs/access.log combined

        WSGIDaemonProcess helloworldapp user=www-data group=www-data threads=5
        WSGIProcessGroup helloworldapp
        WSGIScriptAlias / /var/www/FLASKAPPS/helloworldapp/helloworldapp.wsgi
        Alias /static/ /var/www/FLASKAPPS/helloworldapp/static
        <Directory /var/www/FLASKAPPS/helloworldapp/static>
            Order allow,deny
            Allow from all
        </Directory>
      </VirtualHost>
  - content: |
      #!/app/.venv/bin/python3
      import sys
      sys.path.insert(0,"/app/2022-cloud-security/flask-app/")
      from flask-app import app as application
runcmd:
 - apt-get update
 - apt-get install apache2 libapache2-mod-wsgi python3-dev git python3
 - a2enmod wsgi
 - mkdir /app
 - git clone https://github.com/joelbcastillo/2022-cloud-security/ /app
 - sudo python3 -m venv /app/.venv
 - source virtualenv /app/.venv/bin/activate && pip install -r /app/2022-cloud-security/flask-app/requirements.txt
 - a2ensite api.conf
 - mkdir -p /var/www/cloud-security.jbc.dev/logs
 - chown -R www-data:www-data cloud-security.jbc.dev
 - /etc/init.d/apach2 reload
EOF
}

resource "aws_autoscaling_group" "asg_web_app" {
  lifecycle {
    create_before_destroy = true
  }

  name                = "${aws_launch_configuration.lc_web_app.name}"
  load_balancers      = ["${aws_elb.elb_app.name}"]
  vpc_zone_identifier = ["${aws_subnet.private_az1.id}", "${aws_subnet.private_az2.id}", "${aws_subnet.private_az3.id}"]
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  min_elb_capacity    = 1

  launch_configuration = "${aws_launch_configuration.lc_web_app.name}"

  depends_on = [aws_nat_gateway.nat]

  tag {
    key                 = "Name"
    value               = "flask-api"
    propagate_at_launch = true
  }
}
