output "ec2_public_ip" {
  description = "IP público do EC2 (usar como HOST e API_ADDRESS nos secrets do GitHub Actions)"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Endpoint do RDS (usar como DB_HOST nos secrets do GitHub Actions)"
  value       = aws_db_instance.myapp_db.address
}
