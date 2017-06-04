<#
.SYNOPSIS
    Get-NestedGroupmember -= 
 
 #>

<# Get-NestedGroupMember
	.DESCRIPTION
		Accepts a group name as string, and return an array of every user that is a member of that group, including users that are members of nested groups.
        For instance if the requested group is "group2" and the structure looks like:
            Group2:
                Group1
                Joe Blogs

            Group1:
                Mike Jones

        Both Joe and Mike will be in the returned

	.PARAMETER  
		$Group (Default)
			Accepts the name of an AD Group
	 
	.EXAMPLE
		$MyGroup = "A Group"
        $MyUsers = Get-NestedGroupMember $MyGroup
		write-host $MyUsers | Select-object Givenname,Surname,UserPrincipalName
            Givenname   Surname     UserPrincipalName
            ---------   -------     -----------------
            Joe         Bloggs      Joe.Bloggs@domain.com
            Mike        Jones       Mike.Jones@domain.com   
#>
function Get-NestedGroupMember {
    [CmdletBinding()] 
    param (
        [Parameter(Mandatory)] [string]$Group 
    )
  
 
  ## Find all members in the group specified 
  $GroupUsers = @()

  Log-write -logpath $Script:LogPath -linevalue "`tEnumerating $Group membership"
  $members = Get-ADGroupMember -Identity $Group | ForEach-Object {get-aduser $_.Samaccountname -Properties UserPrincipalName}
        foreach ($member in $members){

          ## If any member in that group is another group just call this function again 

        if ($member.objectClass -eq 'group'){
            $NestedGroup = $member.Name
            Log-write -logpath $Script:LogPath -linevalue "`t`t`tFound sub-group: $NestedGroup"
            Get-NestedGroupMember -Group $NestedGroup

          }else{
          ## otherwise, just  output the non-group object (probably a user account) 
                
          $GroupUsers += $member

          }#End If
      }#End ForEach
    return $GroupUsers

  }#End Function





