# --- VPC & IGW ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "image-processor-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "image-processor-${var.environment}-igw"
  }
}

# --- Subnets ---
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1) # Ej: 10.0.1.0/24
  availability_zone = var.az_a

  tags = {
    Name = "image-processor-${var.environment}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2) # Ej: 10.0.2.0/24
  availability_zone = var.az_b

  tags = {
    Name = "image-processor-${var.environment}-public-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11) # Ej: 10.0.11.0/24
  availability_zone = var.az_a

  tags = {
    Name = "image-processor-${var.environment}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 12) # Ej: 10.0.12.0/24
  availability_zone = var.az_b

  tags = {
    Name = "image-processor-${var.environment}-private-b"
  }
}

# --- NAT Gateways & EIPs ---
resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "image-processor-${var.environment}-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  # Si solo hay 1 NAT, va en la subred pública A. Si hay 2, el segundo va en la B.
  subnet_id     = count.index == 0 ? aws_subnet.public_a.id : aws_subnet.public_b.id

  tags = {
    Name = "image-processor-${var.environment}-nat-${count.index}"
  }
  depends_on = [aws_internet_gateway.igw]
}

# --- Route Tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "image-processor-${var.environment}-rt-public"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "image-processor-${var.environment}-rt-private-a"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    # Si hay 2 NATs usa el índice 1, de lo contrario reutiliza el índice 0
    nat_gateway_id = aws_nat_gateway.nat[var.nat_gateway_count > 1 ? 1 : 0].id
  }

  tags = {
    Name = "image-processor-${var.environment}-rt-private-b"
  }
}

# --- Route Table Associations ---
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

# --- Security Groups ---
resource "aws_security_group" "upload_lambda" {
  name        = "sg-upload-lambda-${var.environment}"
  description = "SG for Upload Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow HTTPS egress to VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_security_group" "crop_lambda" {
  name        = "sg-crop-lambda-${var.environment}"
  description = "SG for Crop Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow HTTPS egress to VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "sg-vpce-sqs-${var.environment}"
  description = "SG for SQS VPC Endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTPS from Upload Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.upload_lambda.id]
  }

  ingress {
    description     = "Allow HTTPS from Crop Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.crop_lambda.id]
  }
}

# --- VPC Endpoints ---
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_a.id, aws_route_table.private_b.id]
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [aws_security_group.vpce_sqs.id]
  private_dns_enabled = true
}