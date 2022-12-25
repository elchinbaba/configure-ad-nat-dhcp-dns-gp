# Check if the ADDSDeployment module is installed
if (!(Get-Module -Name ADDSDeployment -ListAvailable)) {
  # Install the ADDSDeployment module if it is not already installed
  Install-Module -Name ADDSDeployment
}

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Install the necessary roles and features
Install-WindowsFeature AD-Domain-Services, DHCP, DNS

# Promote the server to a domain controller and create a new domain
Install-ADDSForest `
  -CreateDnsDelegation:$false `
  -DatabasePath "C:\Windows\NTDS" `
  -DomainMode "Win2012R2" `
  -DomainName "elchin.local" `
  -DomainNetbiosName "ELCHIN" `
  -ForestMode "Win2012R2" `
  -InstallDns:$true `
  -LogPath "C:\Windows\NTDS" `
  -NoRebootOnCompletion:$false `
  -SysvolPath "C:\Windows\SYSVOL" `
  -Force:$true

# Enable NAT for the internal network interface
New-NetNat -Name "NAT" -InternalIPInterfaceAddressPrefix "192.168.0.0/24"

# Configure the DHCP server
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NAT)"
New-DhcpServerv4Scope -Name "elchin.local" -StartRange 192.168.0.2 -EndRange 192.168.0.254 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -DnsDomain "elchin.local" -DnsServer 192.168.0.1

# Configure the DNS server
Set-DnsServerPrimaryZone -Name "elchin.local" -ReplicationScope Forest
Set-DnsServerGlobalNameZone -Name "elchin.local" -ReplicationScope Forest
Set-DnsServerZoneTransferPolicy -Name "elchin.local" -AllowTransfers "ToServers"
Set-DnsServerGlobalNameZone -Name "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.l.c.h.i.n.ip6.arpa" -ReplicationScope Forest
Set-DnsServerZoneTransferPolicy -Name "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.l.c.h.i.n.ip6.arpa" -AllowTransfers "ToServers"

# (Optional) Configure Group Policy
# Check if the GroupPolicy module is installed
if (!(Get-Module -Name GroupPolicy -ListAvailable)) {
  # Install the GroupPolicy module if it is not already installed
  Install-Module -Name GroupPolicy
}

# Import the GroupPolicy module
Import-Module GroupPolicy

# Create a new Group Policy object (GPO)
New-GPO -Name "Default Domain Policy"

# Set the UserAuthenticationRequired property to $true
Set-GPO -Name "Default Domain Policy" -UserAuthenticationRequired $true
