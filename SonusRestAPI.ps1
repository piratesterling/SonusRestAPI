$tstamp = Get-Date -format "dd-MMM-yyyy HH:mm";

$curDir = $PSScriptRoot;
cd $curDir;
$localLog = "$curDir\MyHistory.log";
$conf = Get-Content ".\config.json" | Out-String | ConvertFrom-Json ;
$codes = Get-Content ".\SonusFails.json" | Out-String | ConvertFrom-Json ;
Import-Module -force "$PSScriptRoot\sonus.psm1";

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
##############################################################################################
##  First we build an Array for encrypting our login and cookies and store this in @props.
##############################################################################################
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()



## If using powershell core v6, ALL of the above can be omitted.
$props = @{};

## If using powershell core v6, uncomment this line.
# $props = @{ SkipCertificateCheck = $true };

##############################################################################################
## Get credentials from user.  We get username from UName in our conf file, than ask the 
## user to type in their password.  --Have not yet been able to do this with json
##############################################################################################
$user        = $conf.UserInfo.uName; 
$securePass  = $pass = Read-Host -Prompt 'Password' -AsSecureString
$PasswordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
$pass        = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPtr)

# Free the pointer
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPtr)

$c = "Username=$user&Password=$pass";
##############################################################################################
##  Now we list out the possible systems to log into, and when selection is made, we grab 
##  The URl from the Json that corresponds to that site and place into variable $mycust and
##  $mylogin for useage.   in the Json file, any entry with lg is for initial login, and 
##  any entry with soGt is for Sonus-Get/Put/Push.  This is the entry that is provided to 
##  functions to scope information.
##############################################################################################
clear-host;
write-host "`n`n`n`t`t1. ops-cl1gw1
            `n`t`t2. ops-cl1gw2 
            `n`t`t3. qa-cl1gw1
            `n`t`t4. qa-cl1gw2
            `n`t`t5. dops-cl1gw1
            `n`t`t6. Prod1
            `n`t`t7. Prod2";
            
$mc0 = Read-host "`n`t`tWhich server are we scoping?";
$cs=$conf.sites;
$custs =$conf.stename;
$mylogin="lgU{0}" -f $mc0;
$mycust="soGt{0}" -f $mc0;
$myste=$custs.$mc0;
$mSa1=$cs.$mylogin;
$mSa2=$cs.$mycust;
##############################################################################################
##  Initial login to server, using a URI built from Json (Lgu entry) + rest/login string.
##  This is where we get the cookie needed to re-link to server, stored in $props, used 
##  within the functions. (Necessary for Ribbon "conversation holder".
##############################################################################################
$webrequest = Invoke-WebRequest @props -Uri $mSa1 `
                                       -SessionVariable websession `
                                       -body $c `
                                       -Method POST;
    $webrequest_xml =  [xml]$webrequest.Content.trim();
    if(!($webrequest_xml.root.status.http_code -match 200)){
        $retcode = $webrequest_xml.root.status.app_status.app_status_entry.code;
        $myFailure= $codes.$retcode;
        Clear-Host;
        Write-Host "`n`n`n`t`t$($webrequest_xml.root.status.http_code) - $myFailure" `
                -ForegroundColor Red; 
        Write-Output "$tstamp -- $user failed login for: `
            $($webrequest_xml.root.status.http_code) - $myFailure" `
            | out-file $localLog -Append;
        Write-Host "`n`t`t Initial Login has failed. Exiting Program!";
        Start-Sleep -s 5;
        return;
    }
$props.websession = $websession
##############################################################################################
##  Now we offer the different options for scoping on the Specific server that we are working
##  on.  Each selection has an option number that corresponds to a Function call with options.
##  after the function call is initiated, the action is completed, and the session is ended.
##  --Need to find a way to action on a secondary or more Function call and provide a solution
##  for closing out the session through commands so that new login is not needed per call. 
##############################################################################################
clear-host;
$myMatrix = Read-Host "`n`n`n`t`tIs this a:`
                                (1).Specific Query `
                                (2).Customer Query `
                                (3).Setup New system `
                                (4).Manual Add Auth/Reg? `
                                (5).Add SipServer `
                                (6).Get current License Count `
                                (7).Get system SG count `
                                (8).Check Cust Config `
                                (9).Remove Customer";
 
    if     ($myMatrix -eq '1'){
        Get-RibbonInfo  -mSa2 $mSa2 `
              	        -conf $conf `
                        -codes $codes `
                        -log $localLog `
                        -myste $myste;
	}
    elseif ($myMatrix -eq '2'){
    	Get-MyCustomer  -mSa2 $mSa2 `
               	        -conf $conf `
                        -codes $codes `
                        -log $localLog `
                        -myste $myste;
	}
    elseif ($myMatrix -eq '3'){
        New-MyServer  -mSa2 $mSa2 `
               	      -conf $conf `
                      -codes $codes `
                      -log $localLog `
                      -myste $myste;
	}
	elseif ($myMatrix -eq '4'){
    	Set-MyRegAuth  -mSa2 $mSa2 `
               	       -conf $conf `
                       -codes $codes `
                       -log $localLog `
                       -myste $myste;
	}
	elseif ($myMatrix -eq '5'){
        Set-AddSipServer  -mSa2 $mSa2 `
               	          -conf $conf `
                          -codes $codes `
                          -log $localLog `
                          -myste $myste;
	}
	elseif ($myMatrix -eq '6'){
    	Get-MyAvailLic  -mSa2 $mSa2 `
               	        -conf $conf `
                        -codes $codes `
                        -log $localLog `
                        -myste $myste;
	}
	elseif ($myMatrix -eq '7'){
        Get-SgCounts  -mSa2 $mSa2 `
              	      -conf $conf `
                      -codes $codes `
                      -log $localLog `
                      -myste $myste;
	}
    elseif ($myMatrix -eq '8'){
        $pltfrm = $conf.stename.$mc0;
        $custDir = "{0}/{1}" -f $PSScriptRoot,$pltfrm; 
        cd $custDir;

        $list2 = dir;
        $test = $list2.Name;
        $sgname = $test -replace '(.*?)_pstn','$1' -replace '(.*?)_teams','$1';
        clear-host;
        $sgname | Get-Unique;
        
        $mycust = Read-Host "`n`n`n`t`tWhich customer?";
        
        Get-AllConfig -mycust $mycust `
                      -pltfrm $pltfrm `
                      -log $localLog `
                      -codes $codes ;
	}
    elseif ($myMatrix -eq '9'){
        Get-ChecksForRemoval  -mSa2 $mSa2 `
              	              -conf $conf `
                              -codes $codes `
                              -log $localLog `
                              -myste $myste;
	}

