
# Please configure the following in the USER SETTINGS
# Under: Program
# Set $global:lccSLogPath, the log file root file name, ex: "25LiveScheduler-log";
# Set $global:lccSScreenOutput, to the screen output root file name, ex: "25LiveScheduler-screenoutput";
# As an Administrator, run the following command (only need to run once) from PowerShell:
# > Set-ExecutionPolicy UnRestricted;
# URL
# Create $lccS25LiveCreateNewFileURL, for each URL, ex: "http://yoursite.edu/25Live/CreateDatain/CreateNewFile/B561";
# Email
# Set $lccBSendEmail, to $true to send emails, $false for no emails
# Set $lccSEmailServer, to an email server, ex: "mail.oursite.edu";
# Set $lccSEmailRecipientAddress, to an email recipient address, ex: "user@yoursite.edu";
# Set $lccSEmailRecipientName, to an email recipient name, ex: "Some User";
# Set $lccSEmailSenderAddress, to an email sender address, ex: "user@yoursite.edu";
# Set $lccSEmailSenderName, to an email sender name, ex: "Some User";
# Set $lccSEmailSubject, to an email subject, ex: "25Live Scheduler Notification: ";
# Set $global:lccSEmailBody, to an email body (header), ex: "25Live Scheduler Notification";

# -----------------------
# PROGRAM CONTROLLED SETTINGS
$lccS25LiveCreateNewFileURLs=@();

# -----------------------
# USER SETTINGS
# Program
$global:lccSLogPath="[drive]:\ctcDev\25Live\Scheduling\25LiveScheduler-log";
$global:lccSScreenOutput="[drive]:\ctcDev\25Live\Scheduling\25LiveScheduler-screenoutput";
# URL
$lccS25LiveCreateNewFileURLs+="http://yoursite.edu/25Live/CreateDatain/CreateNewFile/B561";
$lccS25LiveCreateNewFileURLs+="http://yoursite.edu/25Live/CreateDatain/CreateNewFile/B562";
$lccS25LiveCreateNewFileURLs+="http://yoursite.edu/25Live/CreateDatain/CreateNewFile/B563";
# Email
$lccBSendEmail=$false;
$lccSEmailServer="yourmailserver.edu";
$lccSEmailRecipientAddress="recipient@yoursite.edu";
$lccSEmailRecipientName="Your Recipient";
$lccSEmailSenderAddress="sender@yoursite.edu";
$lccSEmailSenderName="Your Sender";
$lccSEmailSubject="25Live Scheduler Notification: ";
$global:lccSEmailBody="25Live Scheduler Notification";

# -----------------------
# PROGRAM CONTROLLED SETTINGS
$lccSEmailRecipient="$lccSEmailRecipientName <$lccSEmailRecipientAddress>";
$lccSEmailSender="$lccSEmailSenderName <$lccSEmailSenderAddress>";
$global:lccSUserInput = "";
$lccDTDateTime = Get-Date;
$lccSDateTime = $lccDTDateTime.ToString("yyyyMMdd")
$global:lccSLogPath+="-$lccSDateTime.txt";
$global:lccSScreenOutput+="-$lccSDateTime.txt";
# -----------------------

Function lccFLogInfo($lccParamSRecord)
{
$lccDTDate=Get-Date;
If ($global:lccSLogPath.length -gt 0)
	{
	Write-Host "$lccDTDate`t$lccParamSRecord";
	Add-Content $global:lccSLogPath "$lccDTDate`t$lccParamSRecord";
	}
}

Function lccFMain()
{
lccFLogInfo "[lccFMain] STARTED";
Write-Host "lccSEmailRecipient ["$lccSEmailRecipient"]";
lccFLogInfo "[lccFMain] Set Execution Policy";
ForEach ($lccURLLoop in $lccS25LiveCreateNewFileURLs)
	{
	lccFLogInfo "Processing URL: $lccURLLoop";
	Try
		{
		lccFLogInfo "[lccFMain] Downloading URL Content";
		(New-Object Net.WebClient).DownloadString($lccURLLoop) | Out-File $global:lccSScreenOutput -Append;
		$global:lccSEmailBody+="`r`nURL Processed: $lccURLLoop";
		}
	Catch [System.Exception]
		{
		$global:lccSEmailBody+="`r`nURL Process ERROR: $lccURLLoop";
		}
	}

If ($lccBSendEmail -eq $true)
	{
	Try
		{
		If ($lccSEmailServer.length -gt 0 `
			-AND $lccSEmailRecipient.length -gt 0 `
			-AND $lccSEmailSender.length -gt 0 `
			-AND $lccSEmailSubject.length -gt 0 `
			-AND $global:lccSEmailBody.length -gt 0 `
			)
			{
				lccFLogInfo "[lccFMain] Sending Email";
				Send-Mailmessage -To $lccSEmailRecipient -From $lccSEmailSender -Subject $lccSEmailSubject -Body $global:lccSEmailBody -SMTPServer $lccSEmailServer -Priority High -Dno onFailure
			}
		}
	Catch [System.Exception]
		{
		Write-Host "Send Email ERROR: "
		}
	}
#$lccSUserInput = Read-Host -Prompt 'Program Finished';
}

lccFMain;