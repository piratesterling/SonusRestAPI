set-executionpolicy -ExecutionPolicy Bypass;
###############################################################################
##       Version created and tested 4/17/2020 by struex@altigen.com
###############################################################################
##  1. Get-ribbonInfo --- used to gather information on a specific Element for
##                        a specific Gateway.
##  2. Get-Customer   --- Used to get all configuration for a specific numbered 
##                        entry. It assumes that odd numbering is PSTN and even
##                        is Teams.
##  3. New-MyServer   --- Used for New Server install and setup only. This 
##                        function sets up a base system that has been factory   
##                        defaulted or has newly been built. ***It calls up the 
##                        next 11 Functions.***
##  4. Set-MyRegAuth  --- Used to modify registry entry information 
##                    ***Not Complete at this point***
##  5. Add-SipServer  --- If during customer add, only one Teams Sip Server
##                        is added, this function adds the other 2.
##  6. Get-MyAvailLic --- Checks specified Gateway for total Sip Licenses.   
##  7. Get-SgCounts   --- Counts total configured channels per SG than adds
##                        them to give a total configured on the Gateway.
##  8. Get-CompareConfig--Option 2 or 10 must be run against both the PSTN &
##                        Teams customer groups prior to running.***
##                        This process checks settings against "correct" 
##                        settings within each function. It compares those
##                        against the customer settings and flags if setting
##                        for customer does not match.  Error is read as 
##                        "This setting is correct for this customer incorrect
##                        setting."  Customer should be adjusted.
##  9. Remove-Customer--- This function calls up, first 'Get-ChecksForRemoval'
##                        which checks each element in the customer build for 
##      Backup SYSTEM     the PSTN group, ensuring "Description" field names
##          PRIOR         the <customer>_pstn against the SG for the Number that
##      to running 9.     was entered.  It than does the same for each element
##                        in the <customer>_teams.  
##    Recovery is much    Based on the score, if all 11 elements match, it will
##    quicker this way.   call up Remove-Customer, give a summary of what is 
##                        is about to occur.  If acknowledged removal occurs.
##                        IF, however, either the score does not match, each 
##                        incorrect entry is flagged, and must be corrected 
##                        prior to Remove-Customer occurring.  As well, if any
##                        key other than 'y' pressed at last out, no removal
##                        will occur. 
##  10. Get-AllCustomer---This function requires that you have a count of all
##                        Customer Configured SGs on system.  Once you run 
##                        this option, the first thing it does is delete any
##                        existing Gateway Folder in the running directory.
##                        If you want to save what you have, do so manually
##                        prior to running.
###############################################################################
function Get-RibbonInfo{
	param ($msa2,$conf, $log, $codes, $myste)
    $log.info("***** Beginning specific element search on $msa2");
   	clear-host;
   	write-host "`n`n`n`n`n`n";
   	write-host "`t`t1. Sip RemoteAuth Table";
   	write-host "`t`t2. Sip ContactRegistrant";
   	write-host "`t`t3. Sip Profile";
   	Write-host "`t`t4. Sip Server Table";
   	write-host "`t`t5. Sip Transformation Table";
   	write-host "`t`t6. Routing Table";
   	write-host "`t`t7. Signal Gateway";
        
    	
	$mS1 = read-host "What section of Sonus are you reading?"
   	clear-host;
   	write-host "`n`n`n`n`n`n";
    	
	$uI2 = read-host "Which table are you trying to get info for (number)?"
       	if ($mS1 -eq 1){
            $uI1    =   Read-Host "which table entry would you like information on?"
        	$site1  =   "sipremoteauthtable/$uI2/sipremoteauthentry/$uI1";
        	$fI1    =   "sipremoteauthentry"
        	$soUri  =   '{0}{1}' -f $mSa2,$site1;
        }

        elseif ($mS1 -eq 2){
            $uI1     =  Read-Host "which table entry would you like information on?"
            $site1   =  "sipcontactregistrant/$uI2/sipregistrantentry/$uI1";
            $fI1     =  "sipregistrantentry"
            $soUri   =  '{0}{1}' -f $mSa2,$site1;
        }
        
        elseif ($mS1 -eq 3){
            $site1  =   $fI1 = "sipprofile";
        	$soUri  =   '{0}{1}/{2}' -f $mSa2,$site1,$uI2;
        }

        elseif ($mS1 -eq 4){
            $uI1    =   Read-Host "which table entry would you like information on?"
            $site1  =   "sipservertable/$uI2/sipserver/$uI1";
            $fI1    =   "sipserver"
        	$soUri  =   '{0}{1}' -f $mSa2,$site1;
        }

        elseif ($mS1 -eq 5){
		    $uI1    =   Read-Host "which table entry would you like information on?"
            $site1  =   "transformationtable/$uI2/transformationentry/$uI1";
            $fI1    =	"transformationentry"
        	$soUri  =   '{0}{1}' -f $mSa2,$site1;
        }
    
        elseif ($mS1 -eq 6){
		    $uI1    =   Read-Host "which table entry would you like information on?"
            $site1  =	"routingtable/$uI2/routingentry/$uI1";
            $fI1    =	"routingentry"
            $soUri  =   '{0}{1}' -f $mSa2,$site1;
        }

        elseif ($mS1 -eq 7){
            $site1 = $fI1 = "sipsg";
        	$soUri = '{0}{1}/{2}' -f $mSa2,$site1,$uI2;
        }


    	$fileName = "{0}.txt" -f $fI1;
    	$mLs1 = Invoke-WebRequest @props `
                        -Uri $soUri `
					    -Method GET;
    	
    	$mLs1_xml = [xml]$mLs1.Content.Trim();
        if($mLs1_xml.root.status.http_code -match '200'){
            Write-Host "$fI1 successfully found";
            $mLs1_xml.root.$fI1 |out-file $fileName;
    	                    (Get-Content $fileName) |`
    		                Select-String -Pattern "rt_[a-z]" `
                            -NotMatch |`	
			                Out-File $fileName;
        }else{
            $retcode = $mLs1_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            $log.error("$SoUri may not exist: $($mLs1_xml.root.status.http_code) - $myFailure");
            Write-Host "`n`n`n`t`t$($mLs1_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
        $log.info("***** Completed specified element search on $msa2");
};

function Get-MyCustomer{
	param ($msa2,$conf, $log, $myste)
    
	$mloc   =   get-location;
    $gwstorage = "{0}\{1}" -f $mloc,$myste;
	Clear-Host;
	$cstsl  =   Read-Host "`n`n`n`tWhat is the SG number of the customer?";
	$cstnme =   Read-Host "`tWhat is the customer name?";
	$nwdrp  =   "{0}\{1}_pstn" -f $gwstorage,$cstnme;
    $nwdrt  =   "{0}\{1}_teams" -f $gwstorage,$cstnme;
    
    
     
	if (!(Test-Path -Path $nwdrp)){
       	if($cstsl % 2 -ne 0){
       		New-Item -ItemType Directory -Path $nwdrp;
       		$oudir=$nwdrp;
        }
    }
    if (!(Test-Path -Path $nwdrt)){    
	    if($cstsl % 2 -eq 0){
            New-Item -ItemType Directory -Path $nwdrt;
            $oudir=$nwdrt;
	    }      
    }
    $log.info("****** Gathering all elements for Customer $cstsl.");
    ##  Only Grabbing Registratin tables from even numbered,
    ##  Pstn Groups.	
    if($cstsl % 2 -ne 0){

    	$fi1    =   "sipremoteauthentry";
    	$fn1    =   "{0}.txt" -f $fi1;
    	$site1  =   "sipremoteauthtable/$cstsl/sipremoteauthentry/1";
    	$soUri1 =   '{0}{1}' -f $mSa2,$site1;
    	$mLs1   =   Invoke-WebRequest @props -Uri $soUri1 -Method GET;

    	$mLs1_xml = [xml]$mLs1.Content.Trim();
        if(!($mLs1_xml.root.status.http_code -match 200)){
            $retcode = $mLs1_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            $log.error("$site1 not found.--$($mLs1_xml.root.status.http_code) - $myFailure");
            Write-Host "`n`t`tProblem getting $site1";
            Write-Host "`t`t$($mLs1_xml.root.status.http_code) - $myFailure" `
                                                             -ForegroundColor Red;
            
        }
        else{
            $mLs1_xml.root.$fi1 |Out-File $oudir\$fn1;
        	                (Get-Content $oudir\$fn1) |`
    	                    Select-String -Pattern "rt_[a-z]" `
		                                  -NotMatch |`
    		                              Out-File $oudir\$fn1;
        }
    
    	$fi2    =   "sipregistrantentry"
    	$fn2    =   "{0}.txt" -f $fi2;
    	$site2  =   "sipcontactregistrant/$cstsl/sipregistrantentry/1";
    	$soUri2 =   '{0}{1}' -f $mSa2,$site2; 
    	$mLs2   =   Invoke-WebRequest @props -Uri $soUri2 -Method GET;
    	
    	$mLs2_xml = [xml]$mLs2.Content.Trim();
            if(!($mLs2_xml.root.status.http_code -match 200)){
                $retcode = $mLs2_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site2 not found.--$($mLs2_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site2";
                Write-Host "`t`t $($mLs2_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs2_xml.root.$fi2 |Out-File $oudir\$fn2;
    	        (Get-Content $oudir\$fN2) |`
    	        Select-String -Pattern "rt_[a-z]" `
		                      -NotMatch |`
    		                  Out-File $oudir\$fn2;
            }
    }
    ##  Pstn Exceptions done, moving on  ###

	    $site3  =   $fI3 = "sipprofile";
        $soUri3 =   '{0}{1}/{2}' -f $mSa2,$site3,$cstsl;
        $fn3    =   "{0}.txt" -f $fi3;
        $mLs3   =   Invoke-WebRequest @props -Uri $soUri3 -Method GET;
        
        $mLs3_xml = [xml]$mLs3.Content.Trim();
            if(!($mLs3_xml.root.status.http_code -match 200)){
                $retcode = $mLs3_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site3 not found.--$($mLs3_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site3";
                Write-Host "`t`t $($mLs3_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{    
                $mLs3_xml.root.$fi3 |Out-File $oudir\$fn3;
                (Get-Content $oudir\$fn3) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn3;
            }

        $fi4    =   "sipserver"
        $fn4    =   "{0}.txt" -f $fi4;
        $fn4a   =   "{0}2.txt" -f $fi4;
        $fn4b   =   "{0}3.txt" -f $fi4;
        $site4  =   "sipservertable/$cstsl/sipserver/1";
        $soUri4 =   '{0}{1}' -f $mSa2,$site4;

        
        ##  Both PSTN and Teams should get a Server Table 1.
        $mLs4       =   Invoke-WebRequest @props `
                            -Uri $soUri4 `
                            -Method GET;
        $mLs4_xml   = [xml]$mLs4.Content.Trim();
            if(!($mLs4_xml.root.status.http_code -match 200)){
                $retcode = $mLs4_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site4 not found.--$($mLs4_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site4";
                Write-Host "`t`t $($mLs4_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs4_xml.root.$fi4 |Out-File $oudir\$fn4;
                (Get-Content $oudir\$fn4) |`
                        Select-String -Pattern "rt_[a-z]" `
	                                  -NotMatch |`
    	                              Out-File $oudir\$fn4;
            }

    ##  Beginning additional Server ServerTables if Teams only.###
    if($cstsl % 2 -ne 1){
        $site4a =   "sipservertable/$cstsl/sipserver/2";
        $soUri4a=  '{0}{1}' -f $mSa2,$site4a;
        $site4b =   "sipservertable/$cstsl/sipserver/3";
        $soUri4b=   '{0}{1}' -f $mSa2,$site4b;
        ##  Second Teams Servertable
        $mLs4a      =   Invoke-WebRequest @props `
                                    -Uri $soUri4a `
                                    -Method GET;
        
        $mLs4a_xml  =   [xml]$mLs4a.Content.Trim();
            if(!($mLs4a_xml.root.status.http_code -match 200)){
                $retcode = $mLs4a_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site4a not found.--$($mLs4a_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site4a";
                Write-Host "`t`t $($mLs4a_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs4a_xml.root.$fi4 |Out-File $oudir\$fn4a;
                (Get-Content $oudir\$fn4a) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn4a;
            }

        ##  Third Teams servertable
        $mLs4b      =   Invoke-WebRequest @props `
                                     -Uri $soUri4b `
                                     -Method GET;
        $mLs4b_xml  =   [xml]$mLs4b.Content.Trim();
            if(!($mLs4b_xml.root.status.http_code -match 200)){
                $retcode = $mLs4b_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site4b not found.--$($mLs4b_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site4b";
                Write-Host "`t`t $($mLs4b_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{ 
                $mLs4b_xml.root.$fi4 |Out-File $oudir\$fn4b;
                (Get-Content $oudir\$fn4b) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn4b;
            }
    }
    ##  End additional Server ServerTables if Teams only.###
    
        $fi5    =   "transformationentry";
        $fn5    =   "{0}.txt" -f $fi5;
        $site5  =   "transformationtable/$cstsl/transformationentry/1";
        $soUri5 =   '{0}{1}' -f $mSa2,$site5;
        $mLs5   =   Invoke-WebRequest @props `
                             -Uri $soUri5 `
                             -Method GET;
        $mLs5_xml = [xml]$mLs5.Content.Trim();
            if(!($mLs5_xml.root.status.http_code -match 200)){
                $retcode = $mLs5_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site5 not found.--$($mLs5_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site5";
                Write-Host "`t`t $($mLs5_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs5_xml.root.$fi5 |Out-File $oudir\$fn5;
                (Get-Content $oudir\$fn5) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
                              Out-File $oudir\$fn5;
            }

        $fi6    =   "routingentry"
        $fn6    =   "{0}.txt" -f $fi6;
        $site6  =   "routingtable/$cstsl/routingentry/1";
        $soUri6 =   '{0}{1}' -f $mSa2,$site6;
        $mLs6   =   Invoke-WebRequest @props `
                             -Uri $soUri6 `
                             -Method GET;
        $mLs6_xml   = [xml]$mLs6.Content.Trim();
            if(!($mLs6_xml.root.status.http_code -match 200)){
                $retcode = $mLs6_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site6 not found.--$($mLs6_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site6";
                Write-Host "`t`t $($mLs6_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;            
            }
            else{
                $mLs6_xml.root.$fI6 |Out-File $oudir\$fn6;
	            (Get-Content $oudir\$fn6) |`
    	        Select-String -Pattern "rt_[a-z]" `
		                      -NotMatch |`
    	                      Out-File $oudir\$fn6;
            }

        $site7  =   $fI7 = "sipsg";
        $fn7    =   "{0}.txt" -f $fi7;
        $soUri7 =   '{0}{1}/{2}' -f $mSa2,$site7,$cstsl;
        $mLs7   =   Invoke-WebRequest @props `
	        			    -Uri $soUri7 `
		    			    -Method GET;
        $mLs7_xml   =   [xml]$mLs7.Content.Trim();
            if(!($mLs7_xml.root.status.http_code -match 200)){
                $retcode = $mLs7_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site7 not found.--$($mLs7_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site7";
                Write-Host "`t`t $($mLs7_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs7_xml.root.$fI7 |Out-File $oudir\$fn7;
                (Get-Content $oudir\$fn7) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn7;
            }
        if($cstsl % 2 -ne 0){
            if(((Get-ChildItem $nwdrp ).Length) -eq '0'){
                Remove-Item $nwdrp -Force;
                $log.error("Removed supurfluous directory $nwdrt.");
            }
        }
        else{     
        if(((Get-ChildItem $nwdrt ).Length) -eq '0'){
            Remove-Item $nwdrt -Force;
            $log.error("Removed supurfluous directory $nwdrt.");
            }
        }
        $log.info("****** Completed gathering elements for Customer $cstsl.");
};

function New-MyServer{
	param ($msa2,$conf, $myste)
	
	New-SrvTlsProf       -mSa2 $mSa2 -conf $conf;
	New-SrvMCryptProf    -mSa2 $mSa2 -conf $conf;
	New-SrvMedia         -mSa2 $mSa2 -conf $conf;
	New-SrvRemAuth       -mSa2 $mSa2 -conf $conf;
	New-SrvConReg        -mSa2 $mSa2 -conf $conf;
	New-SrvProfs         -mSa2 $mSa2 -conf $conf;
	New-SrvSipTbls       -mSa2 $mSa2 -conf $conf;
	New-SrvTxform        -mSa2 $mSa2 -conf $conf;
	New-SrvRoTbl         -mSa2 $mSa2 -conf $conf;
	New-SrvSG            -mSa2 $mSa2 -conf $conf;
	New-SrvRoTblEntry    -mSa2 $mSa2 -conf $conf;
};
##  Next 11 Functions called by New-MyServer
function New-SrvTlsProf{
    param ($msa2,$conf, $log, $myste)
	$mtlsp1 = @{
    	"Description"		    ="tls_pstn"
    	"TLSVersion"	    	="0"
    	"HandshakeTimeout"      ="30"
    	"mutualAuth"            ="0"
    	"VerifyPeersCertificate"="0"
    	"ClientCipher"          ="6"
    	"ClientCipherSequence"  ="6,5,7,4,3,1,0,2"
    	"ValidateClientFQDN"    ="0"
    	"ValidateServerFQDN"    ="0"
    	"FallbackCompatibleMode"="0"
    }
    		
	$mtlsp2 = @{
    	"Description"           ="tls_teams"
    	"TLSVersion"            ="0"
    	"HandshakeTimeout"      ="30"
    	"MutualAuth"            ="1"
    	"VerifyPeersCertificate"="1"
    	"ClientCipher"          ="6"
    	"ClientCipherSequence"  ="6,5,7,4,3,1,0,2"
    	"ValidateClientFQDN"    ="0"
    	"ValidateServerFQDN"    ="1"
    	"FallbackCompatibleMode"="0"
    }
    		
    $myUri  =   "{0}siptlsprofile/" -f $mSa2;
    $uri1   =   $myUri + 1;
    $uri2   =   $myUri + 2;
    Invoke-RestMethod @props `
                -Method 'Post' `
                -Uri $uri1 `
                -Body $mtlsp1; 
    Invoke-RestMethod @props `
                -Method 'Put'  `
        		-Uri $uri2 `
                -Body $mtlsp2;    
};
function New-SrvMCryptProf{
    param ($msa2,$conf, $myste)
	$mymcp1 = @{
    	"Description"              ="tls_pstn"
    	"OperationOption"          ="2"
    	"CryptoSuite"              ="1"
    	"MasterKeyIdentifierLength"="1"
	}
    $mymcp2 = @{
    	"Description"              ="tls_teams"
    	"OperationOption"          ="1"
    	"CryptoSuite"              ="1"
    	"MasterKeyIdentifierLength"="1"
    }
    $myUri  =   "{0}mediacryptoprofile/" -f $mSa2;
    $uri1   =   $myUri + 1;
    $uri2   =   $myUri + 2;

    Invoke-RestMethod @props `
                -Method 'Put' `
        		-Uri  $uri1 `
                -Body $mymcp1;
    Invoke-RestMethod @props `
                -Method 'Put' `
                -Uri  $uri2 `
                -Body $mymcp2;
};
function New-SrvMedia{
    param ($msa2,$conf, $myste)
   	$med1 = @{
    	"Description"              ="tls_pstn"
    	"CryptoProfileID"          ="1"
    	"DSCP"                     ="46"
    	"DeadCallDetection"        ="1"
    	"DigitRelayPayloadType"    ="101"
    	"DigitRelayType"           ="1"
    	"FAXToneDetection"         ="0"
    	"FaxRelay"                 ="1"
    	"ModemRelay"               ="1"
    	"SilenceSuppression"       ="0"
    	"VoiceFaxProfileID"        ="2"
    }
    $med2 = @{
    	"Description"              ="tls_teams"
    	"CryptoProfileID"          ="2"
    	"DSCP"                     ="46"
    	"DeadCallDetection"        ="1"
    	"DigitRelayPayloadType"    ="101"
    	"DigitRelayType"           ="1"
    	"FAXToneDetection"         ="0"
    	"FaxRelay"                 ="1"
    	"ModemRelay"               ="1"
    	"SilenceSuppression"       ="0"
    	"VoiceFaxProfileID"        ="2,1"
    }
    $med3 = @{
    	"Description"              ="sip_pstn"
    	"CryptoProfileID"          ="0"
    	"DSCP"                     ="46"
    	"DeadCallDetection"        ="1"
    	"DigitRelayPayloadType"    ="101"
    	"DigitRelayType"           ="1"
    	"FAXToneDetection"         ="0"
    	"FaxRelay"                 ="1"
    	"ModemRelay"               ="1"
    	"SilenceSuppression"       ="0"
    	"VoiceFaxProfileID"        ="2"
    }
    $myUri = "{0}medialistprofile/" -f $mSa2;
    $uri1 = $myUri + 1;
    $uri2 = $myUri + 2;
    $uri3 = $myUri + 3;

    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri1 `
				-Body $med1; 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri2 `
				-Body $med2; 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri3 `
				-Body $med3;
};
function New-SrvRemAuth{
    param ($msa2,$conf, $myste)
   	$myra1 = @{
   		"Description"="notinuse_pstn"
   	}
   	$myra2 = @{
   		"Realm"                ="free"
   		"User"                 ="altigen"
   		"EncryptedPassword"    ="altigen1234"
   		"FromURIUserMatch"     ="0"
   	}
   	$myUri = "{0}sipremoteauthtable/" -f $mSa2;
   	$uri1 = $myUri + 1;
   	$uri2 = "{0}/sipremoteauthentry/1" -f $uri1;

   	Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri1 `
				-Body $myra1;
   	Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri2 `
				-Body $myra2;
};
function New-SrvConReg{
    param ($msa2,$conf, $myste)
   	$mcr1 = @{
  		"Description"="notinuse_pstn"
   	}
   	$mcr2 = @{
   		"AOR"                             ="192.168.1.100"
   		"AorTtl"                          ="120"
   		"FailedRegistrationRetryTimer"    ="120"
   		"Uri1"                            ="notinuse_pstn"
   	}
   	$myUri = "{0}sipcontactregistrant/" -f $mSa2;
   	$uri1 = $myUri + 1;
   	$uri2 = "{0}/sipregistrantentry/1" -f $uri1;

   	Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri1 `
				-Body $mcr1; 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri2 `
				-Body $mcr2;
};
function New-SrvProfs{
	$msps1 = @{
   		"Description"="notinuse_pstn"
	}
   	$msps2 = @{
   		"Description"="notinuse_teams"
   	}
    $myUri = "{0}sipprofile/" -f $mSa2;
    $uri1 = $myUri + 1;
    $uri2 = $myUri + 2;

    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri1 `
				-Body $msps1; 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri2 `
				-Body $msps2; 
};
function New-SrvSipTbls{
    param ($msa2,$conf, $myste)
   	$mspt1 = @{
   		"Description"="notinuse_pstn"
   	}
   	$mspt2 = @{
   		"Description"="notinuse_teams"
   	}
   	$mspt3 = @{
   		"AuthorizationOnRefresh"              ="1"
	    "ClearRemoteRegistrationOnStartup"    ="0"
   		"ContactRegistrantTableID"            ="0"
   		"ContactURIRandomizer"                ="0"
   		"DomainName"                          =""
   		"Host"                                ="192.168.1.100"
   		"HostIpVersion"                       ="0"
   		"KeepAliveFrequency"                  ="0"
   		"LocalUserName"                       ="Anonymous"
   		"Monitor"                             ="0"
   		"PeerUserName"                        ="Anonymous"
   		"Port"                                ="5060"
   		"Priority"                            ="1"
   		"Protocol"                            ="1"
   		"RecoverFrequency"                    ="0"
   		"RemoteAuthorizationTableID"          ="0"
   		"RetryNonStaleNonce"                  ="1"
   		"ReuseTimeout"                        ="0"
	    "ReuseTransport"                      ="1"
   		"ServerLookup"                        ="0"
   		"ServerType"                          ="0"
   		"ServiceName"                         ="sip"
   		"SessionURIValidation"                ="0"
   		"StaggerRegistration"                 ="0"
   		"TLSProfileID"                        ="0"
   		"TransportSocket"                     ="4"
   		"Weight"                              ="0"
   	}
   	$mspt4 = @{
   		"AuthorizationOnRefresh"              ="1"
   		"ClearRemoteRegistrationOnStartup"    ="0"
   		"ContactRegistrantTableID"            ="0"
   		"ContactURIRandomizer"                ="0"
   		"DomainName"                          =""
   		"Host"                                ="192.168.1.101"
   		"HostIpVersion"                       ="0"
   		"KeepAliveFrequency"                  ="0"
   		"LocalUserName"                       ="Anonymous"
   		"Monitor"                             ="0"
   		"PeerUserName"                        ="Anonymous"
   		"Port"                                ="5061"
   		"Priority"                            ="1"
   		"Protocol"                            ="4"
   		"RecoverFrequency"                    ="0"
   		"RemoteAuthorizationTableID"          ="0"
   		"RetryNonStaleNonce"                  ="1"
   		"ReuseTimeout"                        ="0"
   		"ReuseTransport"                      ="1"
   		"ServerLookup"                        ="0"
   		"ServerType"                          ="0"
   		"ServiceName"                         ="sip"
   		"SessionURIValidation"                ="0"
   		"StaggerRegistration"                 ="0"
   		"TLSProfileID"                        ="2"
   		"TransportSocket"                     ="4"
   		"Weight"                              ="0"
   	}
   	$myUri = "{0}sipservertable/" -f $mSa2;
   	$uri1 = $myUri + 1;
    $uri2 = $myUri + 2;
    $uri3 = "{0}/sipserver/1" -f $uri1;
    $uri4 = "{0}/sipserver/1" -f $uri2;

    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri1 `
				-Body $mspt1; 
    Invoke-RestMethod @props `
                -Method 'Put'  `
				-Uri  $uri2 `
				-Body $mspt2;
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri3 `
				-Body $mspt3;
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri4 `
				-Body $mspt4;
};
function New-SrvTxform{
    param ($msa2,$conf, $myste)
	$txfm1 = @{
   		"Description"="notinuse_pstn"
   	}
   	$txfm2 = @{
   		"Description"="notinuse_teams"
   	}
   	$txfm3 = @{
   		"ConfigIEState"     ="1"
   		"Description"       ="not in use 1"
   		"InputField"        ="0"
   		"InputFieldValue"   ="\+(.*)"
   		"MatchType"         ="0"
   		"OutputField"       ="0"
   		"OutputFieldValue"  ="\1"
   	}
   	$txfm4 = @{
   		"ConfigIEState"     ="1"
   		"Description"       ="not in use 2"
   		"InputField"        ="0"
   		"InputFieldValue"   ="(.*)"
   		"MatchType"         ="1"
   		"OutputField"       ="0"
   		"OutputFieldValue"  ="+\1"
   	}
    $myUri  = "{0}transformationtable/" `
                            -f $mSa2;
    $uri1   = $myUri + 1;
    $uri2   = $myUri + 2;
    $uri3   = "{0}/transformationentry/1" `
                            -f $uri1;
    $uri4   = "{0}/transformationentry/1" `
                            -f $uri2;

    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri1 `
				-Body $txfm1; 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri2 `
				-Body $txfm2;
    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri3 `
				-Body $txfm3;
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri4 `
				-Body $txfm4;                                                   
};
function New-SrvRoTbl{
    param ($msa2,$conf, $myste)
   	$rtbl1 = @{
   		"Description"   ="from notinuse_pstn"
   	}
   	$rtbl2 = @{
   		"Description"   ="from notinuse_teams"
   	}
   	$myUri = "{0}routingtable/" `
                    -f $mSa2;
   	$uri1 = $myUri + 1;
    $uri2 = $myUri + 2;

    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri1 `
				-Body $rtbl1; 
    Invoke-RestMethod @props `
                -Method 'Put' `
 				-Uri  $uri2 `
				-Body $rtbl2;
};
function New-SrvSG{
    param ($msa2,$conf, $myste)
   	$n1     = $conf.ntwk;
   	$ms     = $conf.ntwk.ms;

   	$rmthst = '{0},{1},{2}' `
        	-f $n1.sip1,$n1.sip2,$n1.dir1;
   	$myMs   = '{0},{1},{2},{3}' `
           	-f $ms.1,$ms.2,$ms.3,$ms.4;
    $myGw = "{0},{0},{0}" -f $n1.gtwy;
    $myMask ="{0},{0},{0},{0}" -f $n1.gtwy2; 
	$sgp1 = @{
		"customAdminState"          ="0"
   		"Channels"                  ="1"
   		"DSCP"                      ="40"
    	"Description"               ="notinuse_pstn"
    	"Early183"                  ="1"
    	"HuntMethod"                ="0"
    	"ICESupport"                ="0"
	    "InboundNATTraversalDetection"=	"0"    
    	"ListenPort_1"              ="5071"
    	"MediaConfigID"             ="3"
    	"Monitor"                   ="3"
    	"NATTraversalType"          ="0"
    	"NetInterfaceSignaling"     ="Ethernet 1-1"
    	"OutboundProxyPort"         ="5071"
		"ProfileID"                 ="1"
    	"Protocol_1"                ="1"
    	"ProxyIpVersion"            ="0"
    	"RelOnQckConnect"           ="0"
    	"RemoteHosts"               =$rmthst
		"RemoteMasks"               =$myGw
    	"RouteTableID"              ="1"
    	"RTPDirectMode"             ="1"
    	"RTPMode"                   ="1"
		"RTPProxyMode"              ="1"
    	"ServerClusterId"           ="1"
		"ServerSelection"           ="1"
    	"SGLevelMOHService"         ="1"
		"SipResponseCodes"          ="0"
    	"TLSProfileID_1"            ="0"
    	"VideoDirectMode"           ="0"
	}
	$sgp2 = @{
		"customAdminState"          ="0"
    	"Channels"                  ="1"
    	"CryptoProfileID"           ="2"
    	"DSCP"                      ="40"
		"Description"               ="notinuse_teams"
    	"HuntMethod"                ="3"
    	"ICESupport"                ="0"
    	"InboundNATTraversalDetection"=	"0"
    	"ListenPort_1"              ="5072"
    	"MediaConfigID"             ="2"
    	"Monitor"                   ="3"
    	"NATTraversalType"          ="0"
    	"NetInterfaceSignaling"     ="Ethernet 1-1"
    	"OutboundProxyPort"         ="5072"
		"ProfileID"                 ="2"
    	"Protocol_1"                ="4"
    	"ProxyIpVersion"            ="0"
    	"RelOnQckConnect"           ="0"
    	"RemoteHosts"               =$myMs
		"RemoteMasks"               =$myMask
    	"RouteTableID"              ="2"
    	"RTPDirectMode"             ="1"
    	"RTPMode"                   ="0"
		"RTPProxyMode"              ="0"
    	"ServerClusterId"           ="2"
    	"ServerSelection"           ="2"
		"SGLevelMOHService"         ="1"
    	"SipResponseCodes"          ="0"
		"TLSProfileID_1"            ="2"
		"VideoDirectMode"           ="0"
	}

    $myUri = "{0}sipsg/" -f $mSa2;
    $uri1 = $myUri + 1;
    $uri2 = $myUri + 2;
 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri1 `
				-Body $sgp1;
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri2 `
				-Body $sgp2;
};
function New-SrvRoTblEntry{
    param ($msa2,$conf, $myste)
    $rtbl3 = @{
    	"CallForked"                ="0"
    	"CallPriority"              ="1"
    	"CancelOthersUponForwarding"="0"
    	"ConfigIEState"             ="1"
    	"DenyCauseCode"             ="16"
    	"Description"               ="to notinuse_pstn"
		"DestinationType"           ="0"
    	"MaximumCallDuration"       ="0"
    	"MediaMode"                 ="0"
    	"MediaSelection"            ="3"
    	"MediaTranscoding"          ="1"
    	"MessageTranslationTable"   ="0"
    	"ProxyHandlingOption"       ="0"
    	"QualityMaxJitterThreshold" ="3000"
    	"QualityMaxRoundTripDelayThreshold"="65535"
    	"QualityMetricCalls"        ="10"
    	"QualityMetricTime"         ="10"
    	"QualityMinASRThreshold"    ="0"
    	"QualityMinLQMOSThreshold"  ="0"
    	"ReRouteTable"              ="0"
    	"RoutePriority"             ="1"
    	"SignalingGroupList"        ="2"
    	"TimeOfDay"                 ="0"
    	"TransformationTable"       ="2"
    	"VideoMediaMode"            ="0"
    }
    $rtbl4 = @{
    	"CallForked"                ="0"
    	"CallPriority"              ="1"
    	"CancelOthersUponForwarding"="0"
    	"ConfigIEState"             ="1"
    	"DenyCauseCode"             ="16"
    	"Description"               ="to notinuse_teams"
    	"DestinationType"           ="0"
    	"MaximumCallDuration"       ="0"
    	"MediaMode"                 ="0"
    	"MediaSelection"            ="2"
    	"MediaTranscoding"          ="1"
    	"MessageTranslationTable"   ="0"
    	"ProxyHandlingOption"       ="0"
    	"QualityMaxJitterThreshold" ="3000"
    	"QualityMaxRoundTripDelayThreshold"="65535"
    	"QualityMetricCalls"        ="10"
    	"QualityMetricTime"         ="10"
    	"QualityMinASRThreshold"    ="0"
    	"QualityMinLQMOSThreshold"  ="0"
    	"ReRouteTable"              ="0"
    	"RoutePriority"             ="1"
    	"SignalingGroupList"        ="1"
    	"TimeOfDay"                 ="0"
    	"TransformationTable"       ="1"
    	"VideoMediaMode"            ="0"
    }
    $myUri = "{0}routingtable/" -f $mSa2;
    $uri3  = "{0}1/routingentry/1" -f $myUri;
    $uri4  = "{0}2/routingentry/1" -f $myUri;

    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri3 `
				-Body $rtbl3; 
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $uri4 `
				-Body $rtbl4;
};

function Set-MyRegAuth{
    param ($msa2,$conf, $log, $myste)
   	$myCust=Read-Host "What are we naming it?";
    $myCstNum = read-host "What are we Numbering it?";
   	$mycra1 = @{
   		"Description"   ="$myCust"
   		"Sequence"      ="$myCstNum"
   	}
   	$mycra2 = @{
   		"Description"   ="$myCust"
   		"Sequence"      ="$myCstNum"
   	}
    

    $myUri1 = "{0}sipremoteauthtable/{1}" `
                        -f $mSa2,$myCstNum;
    $myUri2 = "{0}sipcontactregistrant/{1}" `
                        -f $mSa2,$myCstNum;
    	
	Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $myUri1 `
				-Body $mycra1;
    Invoke-RestMethod @props `
                -Method 'Put' `
				-Uri  $myUri2 `
				-Body $mycra2;
};

function Set-AddSipServer{
    param ($msa2,$conf, $myste)
    $mySipSrvTbl=Read-Host "which Teams SG # are we adding to?";
    $uname=Read-Host "Enter Siptrunk Username";
    $spserv2 = @{
    	"Host"                  =$conf.ntwk.ms.2
        "DomainName"            =$conf.ntwk.ms.2   
      	"HostIpVersion"         ="0"
    	"LocalUserName"         =$uname
    	"Monitor"               ="1"
    	"PeerUserName"          ="Anonymous"
    	"Port"                  ="5061"
    	"Priority"              ="2"
    	"Protocol"              ="4"
    	"RecoverFrequency"      ="0"
    	"ReuseTimeout"          ="0"
    	"ReuseTransport"        ="1"
    	"ServerLookup"          ="0"
    	"ServerType"            ="0"
    	"TLSProfileID"          ="2"
    	"TransportSocket"       ="4"
        "Weight"                ="1"
    }
    $spserv3 = @{
     	"Host"                  =$conf.ntwk.ms.3
        "DomainName"            =$conf.ntwk.ms.3   
      	"HostIpVersion"         ="0"
    	"LocalUserName"         =$uname
    	"Monitor"               ="1"
    	"PeerUserName"          ="Anonymous"
    	"Port"                  ="5061"
    	"Priority"              ="3"
    	"Protocol"              ="4"
    	"RecoverFrequency"      ="0"
    	"ReuseTimeout"          ="0"
    	"ReuseTransport"        ="1"
    	"ServerLookup"          ="0"
    	"ServerType"            ="0"
    	"TLSProfileID"          ="2"
    	"TransportSocket"       ="4"
        "Weight"                ="2"
    }

    $uri1 = "{0}sipservertable/{1}/sipserver/2" `
                        -f $mSa2,$mySipSrvTbl;   
    $uri2 = "{0}sipservertable/{1}/sipserver/3" `
                        -f $mSa2,$mySipSrvTbl;
    
    $srvtbl1 = Invoke-RestMethod @props -Method 'Put' -Uri  $uri1 -Body $spserv2;
    $srvtbl1_xml = [xml]$srvtbl1.Content.Trim();
    
    if(!($srvtbl1_xml.root.status.http_code -match '200')){
        $srvtbl1_xml.root.status;
        $retcode = $srvtbl1_xml.root.status.app_status.app_status_entry.code;
        $myFailure= $codes.$retcode;
        Write-Host "`n`t`t Couldnt add $uri1 .See below error.";
        Write-Host "`t`t$($srvtbl1_xml.root.status.http_code) - $myFailure`n" `
        -ForegroundColor Red;
        
    }
    else{
        Write-Host "`nSuccessfully added $uri1`n";
    }            
    $srvtbl2 = Invoke-RestMethod @props `
                            -Method 'Put' `
				            -Uri  $uri2 `
				            -Body $spserv3;
    $srvtbl2_xml = [xml]$srvtbl2.Content.Trim();
    if(!($srvtbl2_xml.root.status.http_code -match '200')){
        $srvtbl2_xml.root.status;
        $retcode = $srvtbl2_xml.root.status.app_status.app_status_entry.code;
        $myFailure= $codes.$retcode;
        Write-Host "`n`t`t Couldnt add $uri2 .See below error.";
        Write-Host "`t`t$($srvtbl2_xml.root.status.http_code) - $myFailure`n" `
        -ForegroundColor Red;
        
    }
    else{
        Write-Host "`nSuccessfully added $uri2`n";
    } 
};

function Get-MyAvailLic{
    param ($msa2,$conf, $myste)
    $uri1 = "{0}license" -f $mSa2;
    $mylic1 = Invoke-WebRequest @props `
                        -Method Get `
                        -Uri $uri1;
    $mylic1_xml = [xml]$mylic1.Content.trim();
        if(!($mylic1_xml.root.status.http_code -match 200)){
            $retcode = $mylic1_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
        }
            
        Write-Host "`n`n`n`t`t$($mylic1_xml.root.status.http_code) - $myFailure" `
                -ForegroundColor Red;
    $licCount =$mylic1_xml.root.license.AvailableSIPCh;
    $totLicCount = $mylic1_xml.root.license.SIPChannels;
    Clear-Host;
    Write-Host "`n`n`n`n`n`t`tMy sever presently has" `
                                        ," $licCount" `
                                        ," licenses" `
                                        ," from a total of" `
                                        ," $totLicCount`n`n`n" `
        -ForegroundColor White,Yellow,White,Yellow,White;
    

};

function Get-SgCounts{
    param ($msa2,$conf, $myste)

    $site1      =   $fI1 = "sipsg";
    $fileName   =   "$PSScriptRoot/sgcounts.txt"
    $tmpfile    =   "$PSScriptRoot/tmp.txt"
    $counter    =   Read-Host "How Many SGs on system?";
        if(Test-Path $fileName){
            remove-item $fileName;
        }
        if(Test-Path $tmpfile){
            Remove-Item $tmpfile;
        }            
    $mypat=[regex]'\bCha\w+'
        
    for ($i=1; $i -le $counter; $i++){
        $soUri  =   '{0}{1}/{2}' -f $mSa2,$site1,$i;
        $mLs1   =   Invoke-WebRequest @props `
                            -Uri $soUri `
                            -Method Get;
        #$mLs1.Content;
    	$mLs1_xml = [xml]$mLs1.Content.Trim();
        if(!($mLs1_xml.root.status.http_code -match 200)){
            $retcode = $mLs1_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`t`tFailed to gather information for $soUri.";
            Write-Host "`t`t$($mLs1_xml.root.status.http_code) - $myFailure" `
                                                             -ForegroundColor Red;
        }
            

        $mLs1_xml.root.$fI1 | out-file $tmpfile -Append;
        #$mLs1_xml.root.$fI1;
            
        $myMatch = (Get-Content $tmpfile)`
                | select-string -Pattern "\bChan\w+" `
                | out-file $fileName;
    }
    $myttls = (Get-Content $fileName) `
            | select-string -Pattern "\d{1,}" `
            | Foreach-Object {$_.Matches} `
            | ForEach-Object {$_.Groups[0].Value};
    $b =$myttls | measure -sum;
    Write-Host "`n`n`t`t$($b.Sum) total channels on $myste" `
                        -ForegroundColor Yellow;
    start-sleep -s 3;

};

function Get-CompareConfig{
    Param( $mycust, $log, $pltfrm )
    $log.info("Running Get-CompareConfig on $mycust");
    Get-RouteTblPSTN    -mycust $mycust -log $log;
    Get-SgPSTN          -mycust $mycust -log $log;
    Get-TxfrmPSTN       -mycust $mycust -log $log;
    Get-SipServerPSTN   -mycust $mycust -log $log;
    Get-SipProfilePSTN  -mycust $mycust -log $log;
    Get-RouteTblTeams   -mycust $mycust -log $log;
    Get-SgTeams         -mycust $mycust -log $log;
    Get-TxfrmTeams      -mycust $mycust -log $log;
    Get-SipServerTeams  -mycust $mycust -log $log;
    Get-SipProfileTeams -mycust $mycust -log $log `
                        -pltfrm $pltform;
    $log.info("Completed Get-CompareConfig on $mycust");
};
##  Next 10 functions called by  Get-AllConfig
function Get-RouteTblPSTN{
    Param( $mycust, $log )
    $file   = "routingentry.txt"
    $type   = "pstn";
    $myDir  = Get-Location;
    $cust   = "{0}\{1}_{2}" `
                -f $myDir,$mycust, $type;
        
    $pstn_rtlist    = "^MediaMode(.*)[0]$" `
                    ,"^CallPriority(.*)[1]$" `
                    ,"^MessageTranslationTable(.*)[0]$";
                
    $routfile= "{0}\{1}" -f $cust,$file;
    

    ForEach($name in $pstn_rtlist){
        $field=$name; 
        $a = select-string  -pattern $name `
                            -literalpath $routfile `
                            -AllMatches;
        if(!($name = $a)){
            Write-Host "`n$mycust PSTN-- routingentry --$field does not match!  ";
            $log.info("$mycust PSTN-- routingentry --$field does not match!");
        }
    };
    Write-Host "`n Completed checking $mycust PSTN Routing" -ForegroundColor Yellow;
};
function Get-SgPSTN{
    Param( $mycust, $log )
    
    $file   = "sipsg.txt";
    $type   = "pstn";
    $myDir  = Get-Location;
    $cust   = "{0}\{1}_{2}" -f $myDir,$mycust, $type;
    $sgfile = "{0}\{1}" -f $cust,$file;
    $pstn_sg= "^AgentType(.*)[0]$" `
            ,"^AllowRefreshSDP(.*)[1]$" `
            ,"^ChallengeRequest(.*)[0]$" `
            ,"^ConfigIEState(.*)[1]$" `
            ,"^Early183(.*)[1]$" `
            ,"^ICEMode(.*)[0]$" `
            ,"^InteropMode(.*)[0]$" `
            ,"^Monitor(.*)[3]$" `
            ,"^NATTraversalType(.*)[1]$" `
            ,"^NetInterfaceSignaling(.*)[Ethernet 1-1]$" `
            ,"^Protocol_1(.*)[1]$" `
            ,"^RTPMode(.*)[1]$" `
            ,"^RTPProxyMode(.*)[1]$" `
            ,"^RegisterKeepAlive(.*)[1]$" `
            ,"^RingBack(.*)[3-4]$" `
            ,"^SGLevelMOHService(.*)[1]$" `
            ,"^SIPReSync(.*)[0]$";

    ForEach($name in $pstn_sg){
        $field  = $name; 
        $b      = select-string  `
                -pattern $name `
                -literalpath $sgfile `
                -AllMatches;
        if(!($name = $b)){
            Write-Host "`n$mycust PSTN-- sipsg --$field does not match! ";
            $log.info(" $mycust PSTN-- sipsg --$field does not match! ");
        }
    };
    Write-Host "`n Completed checking $mycust PSTN SGs" `
                -ForegroundColor Yellow;
};
function Get-TxfrmPSTN{
    Param( $mycust, $log )
    $type           = "pstn";
    $myDir          = Get-Location;
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;    
    $file           = "transformationentry.txt";
    $txfentryfile   = "{0}\{1}" `
                    -f $cust,$file;
    
    $pstn_txfentry = "^InputField(.*)[0]$" `
                    ,"^InputFieldValue(.*)\+(.*)$" `
                    ,"^MatchType(.*)[1]$" `
                    ,"^OutputField(.*)[0]$" `
                    ,"^OutputFieldValue(.*)[\][1]$";


    ForEach($name in $pstn_txfentry){
        $field = $name; 
        $c = select-string  -pattern $name `
                            -literalpath $txfentryfile `
                            -AllMatches;
        if(!($name = $c)){
            Write-Host "`n$mycust PSTN-- transformationentry--$field does not match! ";
            $log.info(" $mycust PSTN-- transformationentry--$field does not match! ");
        }
    }
    Write-Host "`n Completed checking $mycust PSTN Transformations " `
                    -ForegroundColor Yellow;
};
function Get-SipServerPSTN{
    Param( $mycust, $log )
    $type           = "pstn";
    $myDir          = Get-Location;
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;
    $file           = "sipserver.txt";
    $sipserverfile  = "{0}\{1}" `
                    -f $cust,$file;
    
    $pstn_sipserver = "^Host(.*)atgn1.siptrunk.com$" `
                    ,"^Port(.*)5060$" `
                    ,"^Protocol(.*)[1]$" `
                    ,"^ServiceName(.*)sip$" `
                    ,"^ContactRegistrantTableID(.*)[0]$";
                    


    ForEach($name in $pstn_sipserver){
        $field = $name; 
        $c = select-string  -pattern $name `
                            -literalpath $sipserverfile `
                            -AllMatches;
        if(!($name = $c)){
            Write-Host "`n$mycust PSTN-- sipserver --$field does not match! ";
            $log.info(" $mycust PSTN-- sipserver --$field does not match! ");
        }
    }
    Write-Host "`n Completed checking $mycust PSTN SipServer " `
                    -ForegroundColor Yellow;
};
function Get-SipProfilePSTN{
    Param( $mycust, $log )
    $type           = "pstn";
    $myDir          = Get-Location;
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;    
    $file           = "sipprofile.txt";
    $sipprofile     = "{0}\{1}" `
                    -f $cust,$file;
    
    $pstn_sipprofile = "^StaticHost(.*)atgn1.siptrunk.com:[0-9]{4}$" `
                     ,"^DiagnosticsHeader(.*)[0]$" `
                     ,"^FQDNinContactHeader(.*)[1]$" `
                     ,"^FQDNinFromHeader(.*)[3]$";
 
    ForEach($name in $pstn_sipprofile){
        $field      = $name; 
        $c          = select-string -pattern $name `
                                    -literalpath $sipprofile `
                                    -AllMatches;
        if(!($name = $c)){
            Write-Host "`n$mycust PSTN-- sipProfile --$field does not match! ";
            $log.info(" $mycust PSTN-- sipProfile --$field does not match! ");
        }
    }
    Write-Host "`n Completed checking $mycust PSTN SipProfile " `
                    -ForegroundColor Yellow;
};
function Get-RouteTblTeams{
    Param( $mycust, $log)
    $file           = "routingentry.txt"
    $type           = "teams";
    $myDir          = Get-Location;
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;
        
    $teams_rtlist   = "^MediaMode(.*)[0]$" `
                    ,"^CallPriority(.*)[1]$" `
                    ,"^MessageTranslationTable(.*)[0]$";
                
    $routfile= "{0}\{1}" `
                -f $cust,$file;

    ForEach($name in $teams_rtlist){
        $field=$name; 
        $a = select-string  -pattern $name `
                            -literalpath $routfile `
                            -AllMatches;
        if(!($name = $a)){
            Write-Host "`n$mycust Teams-- routingentry --$field does not match! ";
            $log.info(" $mycust Teams-- routingentry --$field does not match! ");
        }
    };
    Write-Host "`n Completed checking $mycust Teams Routing" `
                    -ForegroundColor Yellow;
};
function Get-SgTeams{
    Param( $mycust, $log )
    $file       = "sipsg.txt";
    $type       = "teams";
    $myDir      = Get-Location;
    $cust       = "{0}\{1}_{2}" `
                -f $myDir,$mycust, $type;
    $sgfile     = "{0}\{1}" `
                -f $cust,$file;
    $teams_sg   = "^AgentType(.*)[0]$" `
                ,"^AllowRefreshSDP(.*)[1]$" `
                ,"^ChallengeRequest(.*)[0]$" `
                ,"^ConfigIEState(.*)[1]$" `
                ,"^Early183(.*)[0]$" `
                ,"^ICEMode(.*)[0]$" `
                ,"^InteropMode(.*)[0]$" `
                ,"^Monitor(.*)[3]$" `
                ,"^NATTraversalType(.*)[1]$" `
                ,"^NetInterfaceSignaling(.*)[Ethernet 1-1]$" `
                ,"^Protocol_1(.*)[4]$" `
                ,"^RemoteHosts(.*)sip(.*),sip[2](.*),si(.*)$" `
                ,"^RemoteMasks(.*)((255.){3}(255),){3}(.*)$" `
                ,"^RTPMode(.*)[1]$" `
                ,"^RTPProxyMode(.*)[1]$" `
                ,"^RegisterKeepAlive(.*)[1]$" `
                ,"^RingBack(.*)[0]$" `
                ,"^SGLevelMOHService(.*)[1]$" `
                ,"^SIPReSync(.*)[0]$";

    ForEach($name in $teams_sg){
        $field = $name; 
        $b = select-string  -pattern $name `
                            -literalpath $sgfile `
                            -AllMatches;
        if(!($name = $b)){
            Write-Host "`n$mycust Teams-- sipsg --$field does not match! ";
            $log.info(" $mycust Teams-- sipsg --$field does not match! ");
        }
    };
    Write-Host "`n Completed checking $mycust Teams SGs" `
                    -ForegroundColor Yellow;
};
function Get-TxfrmTeams{
    Param( $mycust, $log )
    $type           = "teams";
    $myDir          = Get-Location;
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;    
    $file           = "transformationentry.txt";
    $txfentryfile   = "{0}\{1}" `
                    -f $cust,$file;
    
    $teams_txfentry = "^InputField(.*)[0]$" `
                    ,"^InputFieldValue(.*)[(][.][*][)]$" `
                    ,"^MatchType(.*)[0]$" `
                    ,"^OutputField(.*)[0]$" `
                    ,"^OutputFieldValue(.*)[+]\\[1]$";


    ForEach($name in $teams_txfentry){
        $field = $name; 
        $c = select-string  -pattern $name `
                            -literalpath $txfentryfile `
                            -AllMatches;
        if(!($name = $c)){
            Write-Host "`n$mycust Teams-- transformationentry --$field does not match! ";
            $log.info(" $mycust Teams-- transformationentry --$field does not match! ");
        }
    }
    Write-Host "`n Completed checking $mycust Teams Transformations " `
                    -ForegroundColor Yellow;
};
function Get-SipServerTeams{
    Param( $mycust, $log )
    $type           = "teams";
    $myDir          = Get-Location;
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;
    $file           = "sipserver.txt";
    $file2          = "sipserver2.txt";
    $file3          = "sipserver3.txt";
    $sipserverfile  = "{0}\{1}" `
                    -f $cust,$file;
    $sipserverfile2 = "{0}\{1}" `
                    -f $cust,$file2;
    $sipserverfile3 = "{0}\{1}" `
                    -f $cust,$file3;
    
    $teams_sipserver= "^Host(.*)sip.pstnhub.microsoft.com$" `
                    ,"^Priority(.*)[1]$" `
                    ,"^Port(.*)5061$" `
                    ,"^Protocol(.*)[4]$" `
                    ,"^ServiceName(.*)sip$" `
                    ,"^ContactRegistrantTableID(.*)[0]$";
    $teams_sipserver2 = "^Host(.*)sip2.pstnhub.microsoft.com$" `
                    ,"^Priority(.*)[2]$" `
                    ,"^Port(.*)5061$" `
                    ,"^Protocol(.*)[4]$" `
                    ,"^ServiceName(.*)sip$" `
                    ,"^ContactRegistrantTableID(.*)[0]$";
    $teams_sipserver3 = "^Host(.*)sip3.pstnhub.microsoft.com$" `
                    ,"^Priority(.*)[3]$" `
                    ,"^Port(.*)5061$" `
                    ,"^Protocol(.*)[4]$" `
                    ,"^ServiceName(.*)sip$" `
                    ,"^ContactRegistrantTableID(.*)[0]$";                


    ForEach($name in $teams_sipserver){
        $field      = $name; 
        $c          = select-string  -pattern $name `
                            -literalpath $sipserverfile `
                            -AllMatches;
        if(!($name  = $c)){
            Write-Host "`n$mycust Teams-- sipserver --$field does not match! ";
            $log.info(" $mycust Teams-- sipserver --$field does not match! ");        
        }
    }
        ForEach($name in $teams_sipserver2){
        $field      = $name; 
        $ca         = select-string  -pattern $name `
                            -literalpath $sipserverfile2 `
                            -AllMatches;
        if(!($name  = $ca)){
            Write-Host "`n$mycust Teams-- sipserver2 --$field does not match! ";
            $log.info(" $mycust Teams-- sipserver2 --$field does not match! ");
        }
    }
        ForEach($name in $teams_sipserver3){
        $field      = $name; 
        $cb         = select-string  -pattern $name `
                            -literalpath $sipserverfile3 `
                            -AllMatches;
        if(!($name = $cb)){
            Write-Host "`n$mycust Teams-- sipserver3 --$field does not match! ";
            $log.info(" $mycust Teams-- sipserver --$field does not match! ");
        }
    }

    Write-Host "`n Completed checking $mycust Teams SipServer " `
                    -ForegroundColor Yellow;
};
function Get-SipProfileTeams{
    Param( $mycust, $pltfrm, $log )
    $type           = "teams";
    $myDir          = Get-Location;
    if($pltfrm -like 'dops'){
    $stelisting     = "^dops(.*)-gw(\d{2}).voiceforteams.com"
    }
    elseif($pltfrm -like 'prod'){
    $stelisting     = "^prod(\d{2})-gw(\d{2}).voiceforteams.com"
    }
        elseif($pltfrm -like 'qa'){
    $stelisting     = "^qa(.*)-gw(\d{2}).voiceforteams.com"
    }
    $cust           = "{0}\{1}_{2}" `
                    -f $myDir,$mycust, $type;    
    $file           = "sipprofile.txt";
    $sipprofile     = "{0}\{1}" `
                    -f $cust,$file;
    
    $teams_sipprofile = "^$" `
                    ,"^AllowHeader(.*)[1]$" `
                    ,"^DiagnosticsHeader(.*)[1]$" `
                    ,"^FQDNinContactHeader(.*)[3]$" `
                    ,"^FQDNinFromHeader(.*)[1]$" `
                    ,"^OriginFieldUserName(.*)$stelisting$" `
                    ,"^StaticHost(.*)$stelisting\:[0-9]{4}$";
 
    ForEach($name in $teams_sipprofile){
        $field      = $name; 
        $c          = select-string  -pattern $name `
                            -literalpath $sipprofile `
                            -AllMatches;
        if(!($name  = $c)){
            Write-Host "`n$mycust Teams-- sipProfile --$field does not match! ";
            $log.info(" $mycust Teams-- sipProfile --$field does not match! ");
        }
    }
    Write-Host "`n Completed checking $mycust Teams SipProfile " `
                    -ForegroundColor Yellow;
};
function Set-Suspend{
    param ($msa2,`
           $conf, `
           $myste, `
           $sgname, `
           $log, `
           $pstnNum, `
           $teamsNum)
    [int]$pstnNum  = `
    Read-Host "`n`n`n`n`n`t`tWhat is the first SG number of the customer?";
    $mysg   =   "sipsg/$pstnNum";
    $soUri  =   '{0}{1}' -f $mSa2,$mysg;
    
    $sg     =   Invoke-WebRequest @props `
                         -Uri $soUri `
                         -Method GET;
    
    
    $sg_xml = [xml]$sg.Content.Trim();
    $sgn = ($sg_xml.root.sipsg).Description;
    $teamsNum    = $pstnNum + 1;
    
    $sgname_pstn = "{0}_Suspended" -f $sgn ;
    $sg_teams = $sgn -replace '_pstn','_teams';
    $sgname_teams = "{0}_Suspended" -f $sg_teams
    
	$sgp1 = @{
		"customAdminState"          ="0"
        "Channels"                  ="1"
    	"Description"               =$sgname_pstn
        }
	$sgp2 = @{
		"customAdminState"          ="0"
        "Channels"                  ="1"
    	"Description"               =$sgname_teams
        }
    $myUri = "{0}sipsg/" -f $mSa2;
    $uri1 = $myUri + $pstnNum;
    $uri2 = $myUri + $teamsNum;
    
    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri1 `
				-Body $sgp1;
    Invoke-RestMethod @props `
                -Method 'Post' `
				-Uri  $uri2 `
				-Body $sgp2;  
}
function Get-ChecksForRemoval{
    param ($msa2,$conf, $codes, $log, $myste)
    Clear-Host;
    [int]$pstnNum  = `
    Read-Host "`n`n`n`n`n`t`tWhat is the first SG number of the customer?";
    ########################################################################
    ##  First we will get the customer name from the intended group number 
    ##  designated for deletion.  We will use this name to compare each 
    ##  element in the customer build to ensure we do not delete the wrong
    ##  customer's elements.
    ########################################################################
    $mysg   =   "sipsg/$pstnNum";
    $soUri  =   '{0}{1}' -f $mSa2,$mysg;
    
    $sg     =   Invoke-WebRequest @props `
                         -Uri $soUri `
                         -Method GET;
    $sg_xml = [xml]$sg.Content.Trim();
    if(!($sg_xml.root.status.http_code -match '200')){
        $retcode = $sg_xml.root.status.app_status.app_status_entry.code;
        $myFailure= $codes.$retcode;
        Write-Host "`n`n`n`t`t$($sg_xml.root.status.http_code) - $myFailure" `
        -ForegroundColor Red;
        return;
    };
    
    $sgn = ($sg_xml.root.sipsg).Description;
    $sgname = $sgn -replace '(.*?)_pstn','$1';
    ########################################################################
    ##  Now we will check EACH customer element, beginning with the PSTN
    ##  group to ensure that the intended customer is removed.
    ########################################################################

    $pstnElement = @(
        "sipremoteauthtable",
        "sipcontactregistrant",
        "sipservertable",
        "sipprofile",
        "transformationtable",
        "routingtable"
    )
    $mycount = 0;
    foreach( $element in $pstnElement){
        $EleToCheck  = $element + "/" + $pstnNum;
        $soUri =   '{0}{1}' -f $mSa2,$EleToCheck;
        $eCheck   =   Invoke-WebRequest @props `
                                 -Uri $soUri `
                                 -Method GET;
        $eCheck_xml = [xml]$eCheck.Content.Trim();

        $txfmt = $eCheck_xml.root.$element;
        $fullCust = "{0}_pstn" -f $sgname;
        if ($txfmt.Description -match $sgname){
            $mycount ++;
        }
        else{
            ###########################################################################
            ##  grabbing the condition code and reason response returned from Sonus  ##
            ###########################################################################
            if($eCheck_xml.root.status.http_code -match 200){
                $myFailure = "Found record but possibly belonging to another customer";
                }else{$myFailure= $codes.$retcode;}
            $retcode = $eCheck_xml.root.status.app_status.app_status_entry.code;

            Write-Host "`n`n`n`t`t$($eCheck_xml.root.status.http_code) - $myFailure" `
                -ForegroundColor Red;
            Write-host "Check $element Number for $fullCust! It is not $pstnNum." -ForegroundColor Red;
        }
    }
    $teamsElement = @(
        "sipservertable",
        "sipprofile",
        "transformationtable",
        "routingtable",
        "sipsg"
    )
    
    $teamsNum = [int]$pstnNum + 1;
    foreach( $element in $teamsElement){
        $EleToCheck  = $element + "/" + $teamsNum;
        $soUri =   '{0}{1}' -f $mSa2,$EleToCheck;
        $eCheck   =   Invoke-WebRequest @props `
                                 -Uri $soUri `
                                 -Method GET;
        $eCheck_xml = [xml]$eCheck.Content.Trim();
        $txfmt = $eCheck_xml.root.$element;
        $fullCust = "{0}_teams" -f $sgname;
        
        ########################################################################
        ##  Checking total number of successes.  If 
        ##  group to ensure that the intended customer is removed.
        ########################################################################

        if ($txfmt.Description -match $sgname){
            $mycount ++;
        }
        else{
            ###########################################################################
            ##  grabbing the condition code and reason response returned from Sonus  ##
            ###########################################################################
            if($eCheck_xml.root.status.http_code -match 200){
                $myFailure = "Found record but possibly belonging to another customer";
                }else{$myFailure= $codes.$retcode;}
            $retcode = $eCheck_xml.root.status.app_status.app_status_entry.code;

            Write-Host "`n`n`n`t`t$($eCheck_xml.root.status.http_code) - $myFailure" `
                -ForegroundColor Red;
            Write-host "Check $element Number for $fullCust! It is not $teamsNum." -ForegroundColor Red;
        }
    }
    if($mycount -lt 11){
        Write-Host "`n`nCant continue with deletions until issue is cleared up!" `
        -ForegroundColor Red;
        Start-Sleep -s 5;
        return;
        }
        else{
            Remove-Customer -msa2 $msa2 `
                            -conf $conf `
                            -sgname $sgname `
                            -myste $myste `
                            -log  $log `
                            -pstnNum $pstnNum `
                            -teamsNum $teamsNum;
        }
        
};
function Remove-Customer{
    param ($msa2,`
           $conf, `
           $myste, `
           $sgname, `
           $log, `
           $pstnNum, `
           $teamsNum)

    Clear-Host;

    Write-Host "Preparing to remove customer $sgname, groups $pstnNum and $teamsNum" `
    -ForegroundColor Green;
    Write-Host "`n`n`n`n`n";
    $val_entry =Read-host "Validate that Customer $pstnNum and $teamsNum `
    are what you intend to delete by pressing y"
        if (!($val_entry -eq "y")){
            Write-Host "no validation sent, exiting";
            return;
        }
    Write-host "Continuing with deletions";

    $Url1    = "{0}routingtable/{1}/routingentry/1" `
                                    -f $mSa2,$pstnNum;
    $Url1a   = "{0}routingtable/{1}/routingentry/1" `
                                    -f $mSa2,$teamsNum;
    $Url2    = "{0}sipsg/{1}" -f $mSa2,$pstnNum;
    $Url2a   = "{0}sipsg/{1}" -f $mSa2,$teamsNum;
    $Url3    = "{0}routingtable/{1}" -f $mSa2,$pstnNum;
    $Url3a   = "{0}routingtable/{1}" -f $mSa2,$teamsNum;
    $Url4    = "{0}transformationtable/{1}/transformationentry/1" `
                                    -f $mSa2,$pstnNum;
    $Url4a   = "{0}transformationtable/{1}/transformationentry/1" `
                                    -f $mSa2,$teamsNum;
    $Url5    = "{0}transformationtable/{1}" `
                                    -f $mSa2,$pstnNum;
    $Url5a   = "{0}transformationtable/{1}" `
                                    -f $mSa2,$teamsNum;
    $Url6    = "{0}sipservertable/{1}/sipserver/1" `
                                    -f $mSa2,$pstnNum;
    $Url6a   = "{0}sipservertable/{1}/sipserver/1" `
                                    -f $mSa2,$teamsNum;
    $Url6b   = "{0}sipservertable/{1}/sipserver/2" `
                                    -f $mSa2,$teamsNum;
    $Url6c   = "{0}sipservertable/{1}/sipserver/3" `
                                    -f $mSa2,$teamsNum;
    $Url7    = "{0}sipservertable/{1}" -f $mSa2,$pstnNum;
    $Url7a   = "{0}sipservertable/{1}" -f $mSa2,$teamsNum;
    $Url8    = "{0}sipprofile/{1}" -f $mSa2,$pstnNum;
    $Url8a   = "{0}sipprofile/{1}" -f $mSa2,$teamsNum;
    $url9    = "{0}sipcontactregistrant/{1}/sipregistrantentry/1" `
                                    -f $mSa2,$pstnNum;
    $url10   = "{0}sipcontactregistrant/{1}" -f $mSa2,$pstnNum;
    $url11   = "{0}sipremoteauthtable/{1}/sipremoteauthentry/1" `
                                    -f $mSa2,$pstnNum;
    $url12   = "{0}sipremoteauthtable/{1}" -f $mSa2,$pstnNum;
    
    $del1 = Invoke-WebRequest @props -Uri $Url1 -Method Delete;
    	$del1_xml = [xml]$del1.Content.Trim();
        if($del1_xml.root.status.http_code -match '200'){
            Write-Host "$url1 successfully removed";
        }else{
            $retcode = $del1_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del1_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del1a = Invoke-WebRequest @props -Uri $Url1a -Method Delete;
        	$del1a_xml = [xml]$del1a.Content.Trim();
        if($del1a_xml.root.status.http_code -match '200'){
            Write-Host "$Url1a successfully removed";
        }else{
            $retcode = $del1a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del1a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del2 = Invoke-WebRequest @props -Uri $Url2 -Method Delete;
        	$del2_xml = [xml]$del2.Content.Trim();
        if($del2_xml.root.status.http_code -match '200'){
            Write-Host "$Url2 successfully removed";
        }else{
            $retcode = $del2_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del2_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del2a = Invoke-WebRequest @props -Uri $Url2a -Method Delete;
        	$del2a_xml = [xml]$del2a.Content.Trim();
        if($del2a_xml.root.status.http_code -match '200'){
            Write-Host "$Url2a successfully removed";
        }else{
            $retcode = $del2a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del2a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del3 = Invoke-WebRequest @props -Uri $Url3 -Method Delete;
        	$del3_xml = [xml]$del3.Content.Trim();
        if($del3_xml.root.status.http_code -match '200'){
            Write-Host "$Url3 successfully removed";
        }else{
            $retcode = $del3_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del3_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del3a = Invoke-WebRequest @props -Uri $Url3a -Method Delete;
        	$del3a_xml = [xml]$del3a.Content.Trim();
        if($del3a_xml.root.status.http_code -match '200'){
            Write-Host "$Url3a successfully removed";
        }else{
            $retcode = $del3a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del3a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del4 = Invoke-WebRequest @props -Uri $Url4 -Method Delete;
        	$del4_xml = [xml]$del4.Content.Trim();
        if($del4_xml.root.status.http_code -match '200'){
            Write-Host "$Url4 successfully removed";
        }else{
            $retcode = $del4_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del4_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del4a = Invoke-WebRequest @props -Uri $Url4a -Method Delete;
        	$del4a_xml = [xml]$del4a.Content.Trim();
        if($del4a_xml.root.status.http_code -match '200'){
            Write-Host "$Url4a successfully removed";
        }else{
            $retcode = $del4a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del4a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del5 = Invoke-WebRequest @props -Uri $Url5 -Method Delete;
        	$del5_xml = [xml]$del5.Content.Trim();
        if($del5_xml.root.status.http_code -match '200'){
            Write-Host "$Url5 successfully removed";
        }else{
            $retcode = $del5_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del5_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del5a = Invoke-WebRequest @props -Uri $Url5a -Method Delete;
        	$del5a_xml = [xml]$del5a.Content.Trim();
        if($del5a_xml.root.status.http_code -match '200'){
            Write-Host "$Url5a successfully removed";
        }else{
            $retcode = $del5_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del5_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del6 = Invoke-WebRequest @props -Uri $Url6 -Method Delete;
        	$del6_xml = [xml]$del6.Content.Trim();
        if($del6_xml.root.status.http_code -match '200'){
            Write-Host "$Url6 successfully removed";
        }else{
            $retcode = $del6_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del6_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del6a = Invoke-WebRequest @props -Uri $Url6a -Method Delete;
        	$del6a_xml = [xml]$del6a.Content.Trim();
        if($del6_xml.root.status.http_code -match '200'){
            Write-Host "$Url6a successfully removed";
        }else{
            $retcode = $del6a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del6a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del6b = Invoke-WebRequest @props -Uri $Url6b -Method Delete;
        	$del6b_xml = [xml]$del6b.Content.Trim();
        if($del6b_xml.root.status.http_code -match '200'){
            Write-Host "$Url6b successfully removed";
        }else{
            $retcode = $del6b_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del6b_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del6c = Invoke-WebRequest @props -Uri $Url6c -Method Delete;
        	$del6c_xml = [xml]$del6c.Content.Trim();
        if($del6c_xml.root.status.http_code -match '200'){
            Write-Host "$Url6c successfully removed";
        }else{
            $retcode = $del6c_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del6c_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del7 = Invoke-WebRequest @props -Uri $Url7 -Method Delete;
        	$del7_xml = [xml]$del7.Content.Trim();
        if($del7_xml.root.status.http_code -match '200'){
            Write-Host "$Url7 successfully removed";
        }else{
            $retcode = $del7_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del7_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del7a = Invoke-WebRequest @props -Uri $Url7a -Method Delete;
        	$del7a_xml = [xml]$del7a.Content.Trim();
        if($del7a_xml.root.status.http_code -match '200'){
            Write-Host "$Url7a successfully removed";
        }else{
            $retcode = $del7a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del7a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del8 = Invoke-WebRequest @props -Uri $Url8 -Method Delete;
        	$del8_xml = [xml]$del8.Content.Trim();
        if($del8_xml.root.status.http_code -match '200'){
            Write-Host "$Url8 successfully removed";
        }else{
            $retcode = $del8_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del8_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del8a = Invoke-WebRequest @props -Uri $Url8a -Method Delete;
        	$del8a_xml = [xml]$del8a.Content.Trim();
        if($del8a_xml.root.status.http_code -match '200'){
            Write-Host "$Url8a successfully removed";
        }else{
            $retcode = $del8a_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del8a_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del9 = Invoke-WebRequest @props -Uri $Url9 -Method Delete;
        	$del9_xml = [xml]$del9.Content.Trim();
        if($del9_xml.root.status.http_code -match '200'){
            Write-Host "$Url9 successfully removed";
        }else{
            $retcode = $del9_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del9_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del10 = Invoke-WebRequest @props -Uri $Url10 -Method Delete;
        	$del10_xml = [xml]$del10.Content.Trim();
        if($del10_xml.root.status.http_code -match '200'){
            Write-Host "$Url10 successfully removed";
        }else{
            $retcode = $del10_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del10_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del11 = Invoke-WebRequest @props -Uri $Url11 -Method Delete;
        	$del11_xml = [xml]$del11.Content.Trim();
        if($del11_xml.root.status.http_code -match '200'){
            Write-Host "$Url11 successfully removed";
        }else{
            $retcode = $del11_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del11_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };
    $del12 = Invoke-WebRequest @props -Uri $Url12 -Method Delete;
        	$del12_xml = [xml]$del12.Content.Trim();
        if($del12_xml.root.status.http_code -match '200'){
            Write-Host "$Url12 successfully removed";
        }else{
            $retcode = $del12_xml.root.status.app_status.app_status_entry.code;
            $myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($del12_xml.root.status.http_code) - $myFailure" `
            -ForegroundColor Red;
        };

};

function Get-AllCustomer{
	param ($msa2,$conf, $log, $myste)
    
	$mloc   =   get-location;
    $gwstorage = "{0}\{1}" -f $mloc,$myste;
    if(Test-Path $gwstorage){
        Remove-Item -Path $gwstorage -Recurse -Force;
        }
    Clear-Host;
    
	$stepoff  =   Read-Host "`t`tHow many SGs on the gateway?";
    $log.info("`n`n****** Gathering all elements for $stepoff Customers on $myste.");
    $cstsl = 1;
    while($cstsl -le $stepoff){
        $mysg   =   "sipsg/$cstsl";
        $soUri  =   '{0}{1}' -f $mSa2,$mysg;
        $sg     =   Invoke-WebRequest @props `
                                 -Uri $soUri `
                                 -Method GET;
        $sg_xml = [xml]$sg.Content.Trim();
        if(!($sg_xml.root.status.http_code -match '200')){
            $retcode = $sg_xml.root.status.app_status.app_status_entry.code;
            myFailure= $codes.$retcode;
            Write-Host "`n`n`n`t`t$($sg_xml.root.status.http_code) - $myFailure" `
                                                            -ForegroundColor Red;
            return;
        };
    
        $sgn = ($sg_xml.root.sipsg).Description;
        $sgname = $sgn -replace '(.*?)_pstn','$1' `
                        -replace '(.*?)_teams','$1';


    
        if($cstsl % 2 -eq 0){
            $cstnme = "{0}\{1}_teams" -f $gwstorage,$sgname;
        }
        else{
            $cstnme = "{0}\{1}_pstn" -f $gwstorage,$sgname;
        }

	    if (!(Test-Path -Path $cstnme)){
       	        New-Item -ItemType Directory -Path $cstnme;
       		    $oudir=$cstnme;
            }
        #}
        #if (!(Test-Path -Path $cstnme)){    
	    #    if($cstsl % 2 -eq 0){
        #        New-Item -ItemType Directory -Path $nwdrt;
        #        $oudir=$nwdrt;
	    #    }      
        #}
        
    ##  Only Grabbing Registratin tables from even numbered,
    ##  Pstn Groups.	
        if($cstsl % 2 -ne 0){
           	$fi1    =   "sipremoteauthentry";
    	    $fn1    =   "{0}.txt" -f $fi1;
    	    $site1  =   "sipremoteauthtable/$cstsl/sipremoteauthentry/1";
    	    $soUri1 =   '{0}{1}' -f $mSa2,$site1;
    	    $mLs1   =   Invoke-WebRequest @props -Uri $soUri1 -Method GET;

    	    $mLs1_xml = [xml]$mLs1.Content.Trim();
            if(!($mLs1_xml.root.status.http_code -match 200)){
                $retcode = $mLs1_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site1 not found.--$($mLs1_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`tProblem getting $site1";
                Write-Host "`t`t$($mLs1_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            
            }
            else{
                $mLs1_xml.root.$fi1 |Out-File $oudir\$fn1;
            	                (Get-Content $oudir\$fn1) |`
    	                        Select-String -Pattern "rt_[a-z]" `
		                                      -NotMatch |`
    		                                  Out-File $oudir\$fn1;
            }
    
    	    $fi2    =   "sipregistrantentry"
    	    $fn2    =   "{0}.txt" -f $fi2;
    	    $site2  =   "sipcontactregistrant/$cstsl/sipregistrantentry/1";
    	    $soUri2 =   '{0}{1}' -f $mSa2,$site2; 
    	    $mLs2   =   Invoke-WebRequest @props -Uri $soUri2 -Method GET;
    	
    	    $mLs2_xml = [xml]$mLs2.Content.Trim();
                if(!($mLs2_xml.root.status.http_code -match 200)){
                    $retcode = $mLs2_xml.root.status.app_status.app_status_entry.code;
                    $myFailure= $codes.$retcode;
                    $log.error("$site2 not found.--$($mLs2_xml.root.status.http_code) - $myFailure");
                    Write-Host "`n`t`t Problem checking $site2";
                    Write-Host "`t`t $($mLs2_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
                }
                else{
                    $mLs2_xml.root.$fi2 |Out-File $oudir\$fn2;
        	        (Get-Content $oudir\$fN2) |`
    	            Select-String -Pattern "rt_[a-z]" `
		                          -NotMatch |`
    		                      Out-File $oudir\$fn2;
                }
        }
    ##  Pstn Exceptions done, moving on  ###

	    $site3  =   $fI3 = "sipprofile";
        $soUri3 =   '{0}{1}/{2}' -f $mSa2,$site3,$cstsl;
        $fn3    =   "{0}.txt" -f $fi3;
        $mLs3   =   Invoke-WebRequest @props -Uri $soUri3 -Method GET;
        
        $mLs3_xml = [xml]$mLs3.Content.Trim();
            if(!($mLs3_xml.root.status.http_code -match 200)){
                $retcode = $mLs3_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site3 not found.--$($mLs3_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site3";
                Write-Host "`t`t $($mLs3_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{    
                $mLs3_xml.root.$fi3 |Out-File $oudir\$fn3;
                (Get-Content $oudir\$fn3) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn3;
            }

        $fi4    =   "sipserver"
        $fn4    =   "{0}.txt" -f $fi4;
        $fn4a   =   "{0}2.txt" -f $fi4;
        $fn4b   =   "{0}3.txt" -f $fi4;
        $site4  =   "sipservertable/$cstsl/sipserver/1";
        $soUri4 =   '{0}{1}' -f $mSa2,$site4;

        
        ##  Both PSTN and Teams should get a Server Table 1.
        $mLs4       =   Invoke-WebRequest @props `
                            -Uri $soUri4 `
                            -Method GET;
        $mLs4_xml   = [xml]$mLs4.Content.Trim();
            if(!($mLs4_xml.root.status.http_code -match 200)){
                $retcode = $mLs4_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site4 not found.--$($mLs4_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site4";
                Write-Host "`t`t $($mLs4_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs4_xml.root.$fi4 |Out-File $oudir\$fn4;
                (Get-Content $oudir\$fn4) |`
                        Select-String -Pattern "rt_[a-z]" `
	                                  -NotMatch |`
    	                              Out-File $oudir\$fn4;
            }

    ##  Beginning additional Server ServerTables if Teams only.###
    if($cstsl % 2 -ne 1){
        $site4a =   "sipservertable/$cstsl/sipserver/2";
        $soUri4a=  '{0}{1}' -f $mSa2,$site4a;
        $site4b =   "sipservertable/$cstsl/sipserver/3";
        $soUri4b=   '{0}{1}' -f $mSa2,$site4b;
        ##  Second Teams Servertable
        $mLs4a      =   Invoke-WebRequest @props `
                                    -Uri $soUri4a `
                                    -Method GET;
        
        $mLs4a_xml  =   [xml]$mLs4a.Content.Trim();
            if(!($mLs4a_xml.root.status.http_code -match 200)){
                $retcode = $mLs4a_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site4a not found.--$($mLs4a_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site4a";
                Write-Host "`t`t $($mLs4a_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs4a_xml.root.$fi4 |Out-File $oudir\$fn4a;
                (Get-Content $oudir\$fn4a) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn4a;
            }

        ##  Third Teams servertable
        $mLs4b      =   Invoke-WebRequest @props `
                                     -Uri $soUri4b `
                                     -Method GET;
        $mLs4b_xml  =   [xml]$mLs4b.Content.Trim();
            if(!($mLs4b_xml.root.status.http_code -match 200)){
                $retcode = $mLs4b_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site4b not found.--$($mLs4b_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site4b";
                Write-Host "`t`t $($mLs4b_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{ 
                $mLs4b_xml.root.$fi4 |Out-File $oudir\$fn4b;
                (Get-Content $oudir\$fn4b) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn4b;
            }
    }
    ##  End additional Server ServerTables if Teams only.###
    
        $fi5    =   "transformationentry";
        $fn5    =   "{0}.txt" -f $fi5;
        $site5  =   "transformationtable/$cstsl/transformationentry/1";
        $soUri5 =   '{0}{1}' -f $mSa2,$site5;
        $mLs5   =   Invoke-WebRequest @props `
                             -Uri $soUri5 `
                             -Method GET;
        $mLs5_xml = [xml]$mLs5.Content.Trim();
            if(!($mLs5_xml.root.status.http_code -match 200)){
                $retcode = $mLs5_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site5 not found.--$($mLs5_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site5";
                Write-Host "`t`t $($mLs5_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs5_xml.root.$fi5 |Out-File $oudir\$fn5;
                (Get-Content $oudir\$fn5) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
                              Out-File $oudir\$fn5;
            }

        $fi6    =   "routingentry"
        $fn6    =   "{0}.txt" -f $fi6;
        $site6  =   "routingtable/$cstsl/routingentry/1";
        $soUri6 =   '{0}{1}' -f $mSa2,$site6;
        $mLs6   =   Invoke-WebRequest @props `
                             -Uri $soUri6 `
                             -Method GET;
        $mLs6_xml   = [xml]$mLs6.Content.Trim();
            if(!($mLs6_xml.root.status.http_code -match 200)){
                $retcode = $mLs6_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site6 not found.--$($mLs6_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site6";
                Write-Host "`t`t $($mLs6_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;            
            }
            else{
                $mLs6_xml.root.$fI6 |Out-File $oudir\$fn6;
	            (Get-Content $oudir\$fn6) |`
    	        Select-String -Pattern "rt_[a-z]" `
		                      -NotMatch |`
    	                      Out-File $oudir\$fn6;
            }

        $site7  =   $fI7 = "sipsg";
        $fn7    =   "{0}.txt" -f $fi7;
        $soUri7 =   '{0}{1}/{2}' -f $mSa2,$site7,$cstsl;
        $mLs7   =   Invoke-WebRequest @props `
	        			    -Uri $soUri7 `
		    			    -Method GET;
        $mLs7_xml   =   [xml]$mLs7.Content.Trim();
            if(!($mLs7_xml.root.status.http_code -match 200)){
                $retcode = $mLs7_xml.root.status.app_status.app_status_entry.code;
                $myFailure= $codes.$retcode;
                $log.error("$site7 not found.--$($mLs7_xml.root.status.http_code) - $myFailure");
                Write-Host "`n`t`t Problem checking $site7";
                Write-Host "`t`t $($mLs7_xml.root.status.http_code) - $myFailure" `
                                                                 -ForegroundColor Red;
            }
            else{
                $mLs7_xml.root.$fI7 |Out-File $oudir\$fn7;
                (Get-Content $oudir\$fn7) |`
                Select-String -Pattern "rt_[a-z]" `
	                          -NotMatch |`
    	                      Out-File $oudir\$fn7;
            }
        if($cstsl % 2 -ne 0){
            if(((Get-ChildItem $nwdrp ).Length) -eq '0'){
                Remove-Item $nwdrp -Force;
                $log.error("Removed supurfluous directory $nwdrt.");
            }
        }
        else{     
        if(((Get-ChildItem $nwdrt ).Length) -eq '0'){
            Remove-Item $nwdrt -Force;
            $log.error("Removed supurfluous directory $nwdrt.");
            }
        }
        $log.info("****** Completed gathering elements for Customer $cstsl.");
        $cstsl++;
    }
};
