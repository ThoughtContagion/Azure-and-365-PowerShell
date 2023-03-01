Function Inspect-ExternalForwarding{
    $mailboxes = Get-Mailbox -ResultSize Unlimited
    
    $knownDomains = (Get-MgDomain).Id

    $rulesEnabled = @()

    foreach ($mailbox in $mailboxes){
        $rulesEnabled += Get-InboxRule -Mailbox $mailbox.UserPrincipalName | Where-Object {($null -ne $_.ForwardTo) -or ($null -ne $_.ForwardAsAttachmentTo) -or ($null -ne $_.RedirectTo)} | Select-Object MailboxOwnerId, RuleIdentity, Name, ForwardTo, RedirectTo
    }
    if ($rulesEnabled.Count -gt 0) {
        foreach ($domain in $knownDomains){
            $rulesEnabled | Where-Object {($_.ForwardTo -notmatch "$domain") -or ($_.ForwardAsAttachmentTo -notmatch "$domain") -or ($_.RedirectTo -notmatch "$domain")} | Select-Object -Unique
        }
    }
    Return $null
}

Inspect-ExternalForwarding
