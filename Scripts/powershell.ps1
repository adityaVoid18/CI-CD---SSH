# 1. Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server*

# 2. Start and Enable SSH Service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 3. Allow SSH in the Firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# 4. Check SSH-Agent Status
Get-Service ssh-agent

# 5. Enable and Start SSH-Agent
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# 6. Set Permissions for SSH Key
icacls C:\Users\{your_username}\.ssh\bitbucket_work /grant:r {your_username}:(R)

# 7. Add SSH Key to Agent
ssh-add C:\Users\{your_username}\.ssh\bitbucket_work

# 8. Navigate to SSH Configuration Directory
cd C:\ProgramData\ssh

# 9. Restart SSH Service After Modifications
Restart-Service sshd

# 10. Create User-Specific .ssh Directory
mkdir C:\Users\{your_username}\.ssh

# 11. Create Administrator .ssh Directory
mkdir C:\ProgramData\ssh\.ssh

# 12. Generate SSH Key Pair
ssh-keygen -t ed25519 -b 4096 -C "abc@example.com" -f bitbucket_work

# 13. Configure authorized_keys
cd C:\Users\{your_username}\.ssh
echo. > authorized_keys
type bitbucket_work.pub >> authorized_keys
icacls authorized_keys /inheritance:r
icacls authorized_keys /grant:r {your_username}:F

# 14. Configure administrators_authorized_keys
cd C:\ProgramData\ssh
echo. > administrators_authorized_keys
type C:\Users\{your_username}\.ssh\authorized_keys >> C:\ProgramData\ssh\administrators_authorized_keys
icacls administrators_authorized_keys /inheritance:r
icacls administrators_authorized_keys /grant:r {your_username}:F

# 15. Adjust Permissions
icacls "C:\Users\{your_username}\.ssh" /grant:r {your_username}:(OI)(CI)(RX)
icacls "C:\Users\{your_username}\.ssh\bitbucket_work" /grant:r {your_username}:(R)

# 16. Encode Private Key to Base64 (Windows)
[convert]::ToBase64String((Get-Content -Path "${env:USERPROFILE}\.ssh\bitbucket_work" -Encoding Byte))
