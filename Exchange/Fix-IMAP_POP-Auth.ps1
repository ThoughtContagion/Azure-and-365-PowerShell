$smtp = (Get-CasMailbox -ResultSize Unlimited | Where-Object {!$_.SmtpClientAuthenticationDisabled}).Name
	
If ($smtp.Count -NE 0) {
	return $non_smtp |  Out-File "$reports\SCDNR\MailboxeswithSMTPEnabled.txt"
}