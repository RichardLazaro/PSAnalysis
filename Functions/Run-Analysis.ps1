Function Run-Analysis {
    <#
        .NOTES
            Author  : Richard LAZARO
            Email   : richardlazaro@think-ms.net
            Version : 00.09

            Changes tracker :
                00.09 - 2015/06/10 - Script creation

        .SYNOPSIS

        .DESCRIPTION

        .PARAMETER <Parameter-Name>

        .EXAMPLE

        .INPUTS

        .OUTPUTS

        .LINK

        .COMPONENT
    #>

    [CmdletBinding(DefaultParametersetName='All')]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String[]] $Path
    )

    Begin {
        $FctName = $MyInvocation.MyCommand.Name

        If ($PSBoundParameters.Debug) {
            $DebugPreference = 'Continue'
        }

        If ($PSBoundParameters.Verbose) {
            $VerbosePreference = 'Continue'
        }

        If (![String]::IsNullOrEmpty($PSBoundParameters.ErrorAction)) {
            $ErrorActionPreference = $PSBoundParameters.ErrorAction
        } Else {
            $ErrorActionPreference = 'Stop'
        }
    }

    Process {
        Write-Verbose -Message "$FctName : <Start>"
        Write-Debug -Message "$FctName : <Start>"

        $Path | Get-Item -Include '*.ps1', '*.psm1' | ForEach-Object {
            $ScriptPath = $_.FullName

            Write-Debug -Message "$FctName : Process file '$ScriptPath'"

            $Token = New-Object ThinkMS.PowerShell.PSAnalysis.Token -ArgumentList ('Script', $ScriptPath)

            $ChildToken = @(Get-Tokenization -FilePath $ScriptPath) -as [ThinkMS.PowerShell.PSAnalysis.Token[]]

            If ($ChildToken.Count -gt 0) {$Token.Childs.AddRange($ChildToken)}
            Write-Output -InputObject $Token
        }
    }

    End {
        Write-Debug -Message "$FctName : <End>"
    }
}
