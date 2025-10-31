variable "domain_name" {
  description = "Name of the domain bought from AWS" # It makes life a little simpler if using Route53.
  type        = string
  default     = "uselesschatter.com"
}