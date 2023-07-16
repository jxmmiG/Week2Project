output "passwords" {
  value = random_password.password[*].result
}
