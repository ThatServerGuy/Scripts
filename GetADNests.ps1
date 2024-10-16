# Import the necessary modules
Import-Module ActiveDirectory
Import-Module ImportExcel

# Get the domain to search from
$DomainName = (Get-ADDomain).DNSRoot

# Initialize an array to store the results
$results = @()

# Function to recursively get members of all groups in the domain
function Get-AllGroupMembers {
    param (
        [string]$GroupName,
        [string]$ParentGroup = ""
    )

    # Get the members of the group
    $groupMembers = Get-ADGroupMember -Identity $GroupName -Recursive

    foreach ($member in $groupMembers) {
        if ($member.objectClass -eq 'user') {
            # Output user details
            $results += [PSCustomObject]@{
                Group         = $GroupName
                ParentGroup   = $ParentGroup
                MemberName    = $member.SamAccountName
                MemberType    = 'User'
            }
        } elseif ($member.objectClass -eq 'group') {
            # Output group details
            $results += [PSCustomObject]@{
                Group         = $GroupName
                ParentGroup   = $ParentGroup
                MemberName    = $member.SamAccountName
                MemberType    = 'Group'
            }

            # Recursively process nested groups
            Get-AllGroupMembers -GroupName $member.SamAccountName -ParentGroup $GroupName
        }
    }
}

# Get all groups in the domain
$allGroups = Get-ADGroup -Filter * -Server $DomainName

# Loop through all groups and get members
foreach ($group in $allGroups) {
    Get-AllGroupMembers -GroupName $group.SamAccountName
}

# Export the results to an Excel file
$results | Export-Excel -Path "ADGroupMembers.xlsx" -AutoSize
