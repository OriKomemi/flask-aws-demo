provider "aws" {
  region = "us-east-1"
}

# VPC + Subnets
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Security groups
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 8000
    to_port     = 8000
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

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB (RDS)
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnets"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 5
  engine               = "postgres"
  engine_version       = "17.6"
  instance_class       = "db.t3.micro"
  username             = "dbadmin"
  password             = "pass12345"
  skip_final_snapshot  = true
  publicly_accessible  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

# ECR
resource "aws_ecr_repository" "app_repo" {
  name = "flask-aws-demo"
}

# ECS Cluster + Service
resource "aws_ecs_cluster" "main" {
  name = "flask-cluster"
}

resource "aws_iam_role" "ecs_task_exec" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "flask-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([{
    name      = "flask-app"
    image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 8000, hostPort = 8000 }]
    environment = [
      { name = "DB_HOST",     value = aws_db_instance.postgres.address },
      { name = "DB_NAME",     value = "appdb" },
      { name = "DB_USER",     value = "user" },
      { name = "DB_PASSWORD", value = "pass12345" }
    ]
  }])
}

resource "aws_ecs_service" "app_service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

output "app_service" {
  value = aws_ecs_service.app_service.name
}

output "db_endpoint" {
  value = aws_db_instance.postgres.address
}
