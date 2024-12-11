resource "aws_route53_zone" "primary" {
  name = "example.com"
}

output "zone_id" {
  value = aws_route53_zone.primary.id
}
