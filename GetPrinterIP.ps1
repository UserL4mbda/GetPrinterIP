#Usage exemple:
#Get-Printer | ogv -PassThru | Get-PrinterIP

function Get-TCPIPPrinterPortIP {
    param (
        [CmdletBinding(SupportsShouldProcess=$true)]
        [Parameter(ValueFromPipeline)]
        $Printer
    )
    $Printer = if($Printer.Name){
        $Printer
    }else{
        Get-Printer -name $Printer
    }
		#'?' is more explicit than Where-Object 
    (Get-CimInstance Win32_TCPIPPrinterPort | ?{ $_.Name -eq $Printer.PortName }).HostAddress
}

function Get-WSDPrinterPortIP{
    param(
        [CmdletBinding(SupportsShouldProcess=$true)]
        [Parameter(ValueFromPipeline)]
        $Printer
    )
    Process{
        $PrinterName = if($Printer.Name){$Printer.Name}else{$Printer}
        if($PrinterName){
            #Get Name and URL of wsd printers
            $WSDPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\DAFWSDProvider\";
            foreach ($elm in (Get-ChildItem $WSDPath)) {
	    	if(!($elm.Property -eq 'FriendlyName')){
			continue #Sometime the property FriendlyName does not exist!
		}
                if( ($elm |Get-ItemProperty -name FriendlyName).FriendlyName -eq $PrinterName ){
                    $url = ($elm |Get-ItemProperty -name LocationInformation).LocationInformation
										#Keep only IPv4 address
										if($url -match '((\d{1,3}\.){3}\d{1,3})'){
												$result = $Matches[1]
												break
										}
                }
            }
            $result
        }
    }
}

function Get-PrinterIP{
    param(
        [CmdletBinding(SupportsShouldProcess=$true)]
        [Parameter(ValueFromPipeline)]
        $Printer
    )
    Begin{
        $PrinterPortIP = @{
            'WSD Port Monitor' = ${Function:Get-WSDPrinterPortIP};
            'TCPMON.DLL'       = ${Function:Get-TCPIPPrinterPortIP}
        }
    }
    Process{
        $Printer = if($Printer.Name){
            $Printer
        }else{
            Get-Printer -name $Printer
        }

        $PortType = (Get-PrinterPort -Name $Printer.PortName).PortMonitor
        if($PortType){
            $getip = $PrinterPortIP.$PortType
        }

        if($getip){
            &$getip -Printer $Printer
        }
    }
}

