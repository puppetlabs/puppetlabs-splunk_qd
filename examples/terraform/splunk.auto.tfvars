project            = "example-org"
# Ensure you've set up basic DNS out-of-band of this automation
dns_domain         = "gcp.example.com"
dns_zone           = "gcp-example"
# User is shared across both Windows and Linux hosts
user               = "cloud-user"
# Only used on Windows, Linux depends on SSH keys
winrm_passwd       = "HRfpcG8!Q_4aMi"