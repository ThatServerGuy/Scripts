# Import the Active Directory module
Import-Module ActiveDirectory

# Get the domain to search from
$DomainName = (Get-ADDomain).DNSRoot

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
            [PSCustomObject]@{
                Group         = $GroupName
                ParentGroup   = $ParentGroup
                MemberName    = $member.SamAccountName
                MemberType    = 'User'
            }
        } elseif ($member.objectClass -eq 'group') {
            # Output group details
            [PSCustomObject]@{
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
