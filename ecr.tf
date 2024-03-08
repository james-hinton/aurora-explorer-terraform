resource "aws_ecr_repository" "aurora_intensity_processor" {
  name                 = "aurora-intensity-processor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
