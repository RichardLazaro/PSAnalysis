Function Get-Tokenization {
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
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ParameterSetName='FilePath')]
        [String] $FilePath,
        [Parameter(Mandatory=$True, ParameterSetName='FileAST')]
        [System.Management.Automation.Language.Ast] $FileAST
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

        $StatementKey  = @()
        $StatementKey += 'IfStatementAst'
        $StatementKey += 'SwitchStatementAst'
        $StatementKey += 'ForStatementAst'
        $StatementKey += 'ForEachStatementAst'
        $StatementKey += 'DoUntilStatementAst'
        $StatementKey += 'DoWhileStatementAst'
        $StatementKey += 'WhileStatementAst'
    }

    Process {
        Write-Verbose -Message "$FctName : <Start>"
        Write-Debug -Message "$FctName : <Start>"

        Write-Debug -Message "$FctName :   ParameterSetName = $($PSCmdlet.ParameterSetName)"
        Switch ($PSCmdlet.ParameterSetName) {
            'FilePath' {$AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)}
            'FileAST'  {$AST = $FileAST}
        }
        
        $Predicate = {$true}

        $AST.FindAll({$true}, $False) | ForEach-Object {
            $ObjAST = $_
            $ObjASTTypeName = $ObjAST.GetType().Name

            $Token = New-Object ThinkMS.PowerShell.PSAnalysis.Token

            switch ($ObjASTTypeName) {
                {('FunctionDefinitionAst' -eq $_) -or ($_ -eq 'CommandAst' -and $ObjAST.InvocationOperator -ne 'Dot') -or ($StatementKey -contains $_)} {
                    Write-Debug "$FctName : $ObjASTTypeName"

                    $Token.StartLineNbr = $ObjAST.Extent.StartLineNumber
                    $Token.EndLineNbr = $ObjAST.Extent.EndLineNumber
                    $Token.StartColumnNbr = $ObjAST.Extent.StartColumnNumber
                    $Token.EndColumnNbr = $ObjAST.Extent.EndColumnNumber
                }

                # FunctionDefinition
                'FunctionDefinitionAst' {
                    $ObjASTName = $ObjAST.Name

                    $Token.Name = $ObjASTName
                    $Token.Type = 'FunctionDefinition'
                    
                    $ChildToken = (Get-Tokenization -FileAST $ObjAST.Body) -as [ThinkMS.PowerShell.PSAnalysis.Token[]]
                    If ($ChildToken.Count -gt 0) {$Token.Childs.AddRange($ChildToken)}
                }

                # Cmdlet/Function
                {$_ -eq 'CommandAst' -and $ObjAST.InvocationOperator -ne 'Dot'} {
                    $ObjASTName = $ObjAST.CommandElements[0].Value

                    $Token.Name = $ObjASTName
                    If ($InstanciedCommand -contains $ObjectAST) {$Token.Type = 'Command'} Else {$Token.Type = 'Function'}
                }

                # Statement
                {$StatementKey -contains $_} {
                    $Token.Name = $_.Replace('StatementAst','')
                    $Token.Type = 'Statement'
                    
                }

                {('FunctionDefinitionAst' -eq $_) -or ($_ -eq 'CommandAst' -and $ObjAST.InvocationOperator -ne 'Dot') -or ($StatementKey -contains $_)} {
                    Write-Output $Token
                }
            }
        }
        #>
    }

    End {
        Write-Debug -Message "$FctName : <End>"
    }
}
