$Stack = New-Object System.Collections.Stack

            $tokens = @()
            $errors = @()

$Statements  = @()
$Statements += 'IfStatementAst'
$Statements += 'SwitchStatementAst'
$Statements += 'ForStatementAst'
$Statements += 'ForEachStatementAst'
$Statements += 'DoUntilStatementAst'
$Statements += 'DoWhileStatementAst'
$Statements += 'WhileStatementAst'

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Text;

namespace ThinkMS.PowerShell.PSAnalysis
{
    
    
    public enum TokenType
    {
        Unknown = 0,
        Script = 1,
        FunctionDeclaration = 2,
        Function = 3,
        Cmdlet = 4,
        Statement = 5
    }

    public class Token
    {
        public TokenType Type;
        public string Name;
        public int StartLineNbr;
        public int EndLineNbr;
        public int StartColumnNbr;
        public int EndColumnNbr;
        public List<Token> Childs;

        public Token() {
            this.Childs = new List<Token>();
            this.Type = TokenType.Unknown;
        }
    }
}
"@

Function Analyse-PowerShell {
    Param (
        [String[]] $Path
    )

    Begin {
        $AllCommands = Get-Command -All | Select-Object -ExpandProperty Name
    }

    Process {
        $Path | Get-Item -Include '*.ps1', '*.psm1'  | ForEach-Object {
            $ScriptPath = $_.FullName
            $ScriptName = $_.Name


            $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)

            Write-Host $ScriptPath -ForegroundColor Green

            Analyse-PSFunction -AST $AST
        }
    }

    End {
    }
}

Function Analyse-PSFunction {
    Param (
        $AST,
        $Depth = 1
    )

    $AST.FindAll({$true}, $false) `
    | ForEach-Object {
        $ObjectAST = $_

        Switch ($ObjectAST.GetType().Name) {
            'FunctionDefinitionAst' {
                Write-Host "$('  ' * ($Depth+$Stack.Count))$($ObjectAST.Name)" -ForegroundColor Red
                Analyse-PSFunction -AST $ObjectAST.Body -Depth ($Depth + 1)
            }

            {$_ -eq 'CommandAst' -and $ObjectAST.InvocationOperator -ne 'Dot'} {
                $CommandName = $ObjectAST.CommandElements[0]

                If ($AllCommands -contains $CommandName) {
                    Write-Host "$('  ' * ($Depth+$Stack.Count))$CommandName" -ForegroundColor Gray 
                } Else {
                    Write-Host "$('  ' * ($Depth+$Stack.Count))$CommandName" -ForegroundColor Magenta
                }          
            }

            {$Statements -contains $_} {
                If ($Stack.Count -ne 0 -and ($Stack.Peek().Values[0].Get(1) -lt $ObjectAST.Extent.StartLineNumber)) {
                    $Stack.Pop() | Out-Null   
                }
                
                Write-Host "$("  " * (($Depth + $Stack.Count)))$($_.Replace('StatementAst',''))"
                $Stack.Push(@{$_ = @($ObjectAST.Extent.StartLineNumber, $ObjectAST.Extent.EndLineNumber, $ObjectAST.Extent.StartColumnNumber, $ObjectAST.Extent.EndColumnNumber)})
            }
        }
    }
}

#Analyse-PowerShell -Path C:\Users\ng4f669\Documents\Projects\LDAPGen\Sources\LDAPGen_v0.6.2_TestAnalysis\*
#Analyse-PowerShell -Path 'C:\Users\richardl\Documents\Exakis\AIRBUS\LDAP Gen\LDAP Gen v0.6.2\Run-LDAPGenerator.ps1'
Analyse-PowerShell -Path 'C:\Users\richardl\Documents\Personal\GitHub\PSAnalysis\test.ps1'