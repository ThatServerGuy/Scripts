# PowerShell script to analyze file sizes in directories with infinite depth, displaying only 3 levels deep

# Function to convert bytes to a human-readable format
function Convert-Size {
    param ([int64]$Bytes)
    if ($Bytes -lt 1KB) {
        return "${Bytes} B"
    } elseif ($Bytes -lt 1MB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    } elseif ($Bytes -lt 1GB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    } else {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
}

# Recursive function to get folder sizes
function Get-FolderSize {
    param (
        [string]$Path,
        [int]$Level = 0
    )

    $folders = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $folders) {
        try {
            $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $folderObject = [PSCustomObject]@{
                Path = $folder.FullName
                SizeBytes = $size
                SizeReadable = Convert-Size $size
                Level = $Level
            }

            # Output the folder information if within the first 3 levels
            if ($Level -lt 3) {
                $folderObject
            }

            # Recurse into subdirectories
            Get-FolderSize -Path $folder.FullName -Level ($Level + 1)
        } catch {
            Write-Debug "Error processing folder: $folder"
        }
    }
}

# Ensure the path input is treated as an absolute path
function Get-AbsolutePath {
    param (
        [string]$InputPath
    )

    # Handle different input formats
    if (-not [System.IO.Path]::IsPathRooted($InputPath)) {
        if ($InputPath -match '^[a-zA-Z]$') {
            $InputPath += ':\'
        } else {
            $InputPath = Join-Path (Get-Location) $InputPath
        }
    }

    return [System.IO.Path]::GetFullPath($InputPath)
}

# Ask the user to enter a drive letter or directory path
Write-Host "Enter the drive letter or a full directory path (e.g., C:\Users\YourName\Documents)"
$userInput = Read-Host -Prompt 'Path'
$path = Get-AbsolutePath -InputPath $userInput

# Enabling debugging
$DebugPreference = 'Continue'

# Displaying the results and storing in variable
Write-Host "Analyzing, please wait..."
$folderData = Get-FolderSize -Path $path | Sort-Object SizeBytes -Descending

# Display the results
$folderData | Format-Table -AutoSize

# Prompt to save the data
Write-Host "Do you want to save the data? (Y/N)"
$saveData = Read-Host

if ($saveData -eq 'Y') {
    Write-Host "Select the format to save the data:"
    Write-Host "1: CSV (.csv)"
    Write-Host "2: JSON (.json)"
    Write-Host "3: Text File (.txt)"
    $format = Read-Host

    $savePath = Read-Host -Prompt "Enter the full path to save the file (including file name)"

    switch ($format) {
        '1' {
            $folderData | Export-Csv -Path $savePath -NoTypeInformation
        }
        '2' {
            $folderData | ConvertTo-Json | Set-Content -Path $savePath
        }
        '3' {
            $folderData | Format-Table -AutoSize | Out-String | Set-Content -Path $savePath
        }
    }

    Write-Host "Data saved to $savePath"
}

# Resetting debug preference
$DebugPreference = 'SilentlyContinue'

Write-Host "Analysis complete."
