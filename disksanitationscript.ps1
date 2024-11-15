# Disk Sanitization Script
# WARNING: This script will PERMANENTLY erase all data on the selected disk.

function Get-DiskSelection {
    # List all available disks with some information
    $disks = Get-Disk | Select-Object Number, FriendlyName, OperationalStatus, Size, @{Name="IsRemovable";Expression={($_.BusType -eq 'USB')}}
    $disks | Format-Table -AutoSize
    
    # Prompt user to select the disk to sanitize
    $diskNumber = Read-Host "Enter the disk number to sanitize (e.g., 0, 1, 2)"
    $selectedDisk = $disks | Where-Object { $_.Number -eq $diskNumber }
    
    if ($null -eq $selectedDisk) {
        Write-Host "Invalid disk number selected. Exiting script."
        exit
    }
    
    return $selectedDisk
}

function Sanitize-Disk {
    param (
        [Parameter(Mandatory=$true)]
        [int]$DiskNumber
    )

    # Confirm action with the user
    $confirmation = Read-Host "Are you sure you want to erase all data on disk $DiskNumber? (Y/N)"
    if ($confirmation -ne 'Y') {
        Write-Host "Operation aborted. No data will be erased."
        exit
    }

        # If it's not a removable disk, take it offline first
        if (-not (Get-Disk | Where-Object { $_.BusType -eq 'USB' })) {
            Set-Disk -Number $DiskNumber -IsOffline $true
            Write-Host "Disk $DiskNumber is now offline."
        } else {
            Write-Host "Disk $DiskNumber is a removable disk. Skipping 'offline' step."
        }

        # Clear the disk (overwrites it with zeroes)
        Write-Host "Attempting to sanitize disk $DiskNumber..."
        Clear-Disk -Number $DiskNumber -RemoveData -Confirm:$false

        Write-Host "Disk $DiskNumber has been sanitized."

        # Set the disk back online after sanitation, if it was offline
        if (-not (Get-Disk | Where-Object { $_.BusType -eq 'USB' })) {
            Set-Disk -Number $DiskNumber -IsOffline $false
            Write-Host "Disk $DiskNumber is now back online."
        } 
}

# Main script execution
Write-Information -MessageData "Disk Information" -InformationAction Continue
$disks = Get-Disk | Select-Object Number, FriendlyName, OperationalStatus, Size, BusType
$disks | Format-Table -AutoSize

Write-Host "Warning: This script will PERMANENTLY erase all data on the selected disk."
$disk = Get-DiskSelection

Sanitize-Disk -DiskNumber $disk.Number

Write-Host "Disk sanitation complete."
