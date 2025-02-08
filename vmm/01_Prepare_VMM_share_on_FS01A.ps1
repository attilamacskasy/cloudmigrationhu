# Parameters
$shareName = "VMM_Library"
$sharePath = "E:\$shareName"
$permissionsGroup = "Domain Admins"  # Group to grant permissions

# Create the share folder if it doesn't exist
if (-Not (Test-Path -Path $sharePath)) {
    Write-Host "Creating directory: $sharePath" -ForegroundColor Green
    New-Item -Path $sharePath -ItemType Directory -Force
} else {
    Write-Host "Directory already exists: $sharePath" -ForegroundColor Yellow
}

# Set NTFS permissions
Write-Host "Configuring NTFS permissions for $permissionsGroup on $sharePath" -ForegroundColor Green
$acl = Get-Acl -Path $sharePath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$permissionsGroup", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $sharePath -AclObject $acl

# Share the folder
Write-Host "Creating shared folder: $shareName" -ForegroundColor Green
New-SmbShare -Name $shareName -Path $sharePath -FullAccess $permissionsGroup

# Verify the share
Write-Host "Verifying the share..." -ForegroundColor Cyan
Get-SmbShare | Where-Object { $_.Name -eq $shareName }

Write-Host "VMM Library share configured successfully on FS01A!" -ForegroundColor Green
