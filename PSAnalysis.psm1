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
        FunctionDefinition = 2,
        Function = 3,
        Command = 4,
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

        public Token(TokenType type, string name) {
            this.Childs = new List<Token>();
            this.Type = TokenType.Unknown;
            this.Type = type;
            this.Name = name;
        }

        public Token(TokenType type, string name, int startLineNbr, int endLineNbr, int startColumnNbr, int endColumnNbr) {
            this.Childs = new List<Token>();
            this.Type = TokenType.Unknown;
            this.Type = type;
            this.Name = name;
            this.StartLineNbr = startLineNbr;
            this.EndLineNbr = endLineNbr;
            this.StartColumnNbr = startColumnNbr;
            this.EndColumnNbr = endColumnNbr;
        }
    }
}
"@

# Load all functions .ps1 located to <SourceModule>\Functions
Get-ChildItem -LiteralPath "$($MyInvocation.MyCommand.Path.TrimEnd($MyInvocation.MyCommand.Name))Functions" -Filter *.ps1 `
| ForEach-Object {
    . $_.Fullname
}

New-Variable -Name InstanciedCommand -Option AllScope -Value (Get-Command -All | Select-Object -ExpandProperty Name)

Export-ModuleMember -Function Run-Analysis