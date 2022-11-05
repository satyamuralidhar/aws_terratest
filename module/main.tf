resource "random_id" "random" {
  byte_length = 2
  
}
#-----------------------------------------
#cretaing a virtual network 
#-----------------------------------------

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.env}-vpc"
  }
}

#---------------------------------------
#subnet creation of vnet
#----------------------------------------
resource "aws_subnet" "subnet" {
  vpc_id = "${aws_vpc.main.id}"
  count = "${length(var.subnet)}"
  availability_zone = "${element(var.azs,count.index)}"
  //element(list,index)
  cidr_block = "${element(var.subnet,count.index)}"
  //map_public_ip_on_launch = "${aws_subnet.subnet[0].id == true ? true : false}"
  tags = {
    "Name" = "subnet-${count.index+1}"
  }
}

#---------------------------------------
#creating route table
#--------------------------------------- 

resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  depends_on = [
    aws_vpc.main,
    aws_subnet.subnet,
    aws_internet_gateway.gw
  ]
}

#-------------------------------------------
#route table creation
#-------------------------------------------

resource "aws_route_table_association" "table_association" {
  count = length(var.subnet)
  subnet_id = "${aws_subnet.subnet[0].id}"
  route_table_id = "${aws_route_table.route.id}"
  //gateway_id = "${aws_internet_gateway.gw.id}"
}

#----------------------------------------
#internet gateways
#----------------------------------------

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  depends_on = [
    aws_vpc.main,
    aws_subnet.subnet
  ]
}

#-------------------------------------------
#creating security group
#-------------------------------------------


resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow http traffic"
  vpc_id      = "${aws_vpc.main.id}"

  dynamic "ingress" {
    for_each = var.ingress_ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
  tags = merge(
    var.tagging,
    {
    Name = "allow_traffic-${random_id.random.dec}"
    }
  )
  depends_on = [
    aws_internet_gateway.gw,
    aws_vpc.main,
    aws_subnet.subnet
  ]
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-key" 
  public_key = file("${path.module}/id_rsa.pub")

  depends_on = [
  aws_vpc.main

]

}


resource "aws_instance" "linux_instance" {
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.generated_key.key_name}"
  security_groups = [ "${aws_security_group.web_sg.id}" ]
  subnet_id = "${aws_subnet.subnet[0].id}"
  associate_public_ip_address = true
  #create a webserver nginx
  tags = {
    Name = "Webserver-${var.env}"
  }
  depends_on = [
    aws_security_group.web_sg
  ]
  connection {
    type = ssh
    user = ec2-user
    private_key = "${path.module}/id_rsa"
    //host = "${self.publicip}" //toget self public ip or below.
    host = "${aws_instance.linux_instance.public_ip}"

  }

}
output "publickey" {
  value = "${aws_instance.linux_instance.public_ip}"
}