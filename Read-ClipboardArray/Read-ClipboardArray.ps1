<#PSScriptInfo

.VERSION 1.0.0.0

.GUID fa3d2cfd-5aac-49e8-b4ea-3b036396f63e

.AUTHOR Philip Haglund

.COMPANYNAME Gonjer.com

.COPYRIGHT 

.TAGS Clipboard Paste

.LICENSEURI https://github.com/PhilipHaglund/PowerShell/blob/master/Read-ClipboardArray/LICENSE

.PROJECTURI https://github.com/PhilipHaglund/PowerShell/tree/master/Read-ClipboardArray

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>
function Read-ClipboardArray
{
    <# 
        .SYNOPSIS
        Function used to paste an array of objects from the Windows Clipboard.

        .DESCRIPTION 
        Function used to paste an array of objects from the Windows Clipboard to an script variable.
        Default the function will set every object as a string. Using the parameter DataType can specifiy what every object should be tried to be converted to.
        The order for the data type convertion is [System.DateTime], [System.Int32], [System.Int64], [System.Boolean], [System.String].

        .EXAMPLE
        Read-ClipBoardArray
        
        No.[0]: Some data
        No.[1]: to
        No.[2]: paste
        No.[3]: into
        No.[4]: the function
        No.[5]: 

        Empty line will close the loop from importing anything more.
        The input to will be saved to the variable ClipboardArray.
        Each item in the array will be of the data type [System.String].

        .EXAMPLE
        Read-ClipBoardArray -DataType Int32
        
        No.[0]: Some data
        No.[1]: 20170101
        No.[2]: 123
        No.[3]: into
        No.[4]: 876 function
        No.[5]: 

        Empty line will close the loop from importing anything more.
        The input to will be saved to the variable ClipboardArray.
        This example will try to convert every object in the array to an System.Int32. If its not possible it will default back to System.String.
        Array object 2 is the only one that will be converted to a System.Int32 datatype.

        .EXAMPLE
        Read-ClipBoardArray -DataType All
        
        No.[0]: Some data
        No.[1]: 2017-01-01
        No.[2]: 2147483647
        No.[3]: 2147483648
        No.[4]: TRUE
        No.[5]: 

        Empty line will close the loop from importing anything more.
        The input to will be saved to the variable ClipboardArray.
        This example will try to convert every object in the array to all avaiable data types. If its not possible it will default back to System.String.
        The order for the data type convertion is [System.DateTime], [System.Int32], [System.Int64], [System.Boolean], [System.String].
        Array object 0 is a String, object 1 is a DateTime, object 2 is a Int32, object 3 is a Int64 and object 4 is a Boolean.

        .EXAMPLE
        Read-ClipBoardArray -EndChar '?'
        
        No.[0]: Some data
        No.[1]: 2017-01-01
        No.[2]: 2147483647
        No.[3]: 2147483648
        No.[4]: TRUE
        No.[5]: 
        No.[6]: ?

        The questionmark will close the loop from importing anything more.
        The input to will be saved to the variable ClipboardArray.
        This example will not convert any objects in the array, all objects default to System.String.
        The EndChar parameter can be used when the input contains empty rows.

        .EXAMPLE
        Read-ClipBoardArray -EndChar '!' -DataType All
        
        No.[0]: Some data
        No.[1]: 2017-01-01
        No.[2]: 2147483647
        No.[3]: 2147483648
        No.[4]: TRUE
        No.[5]: 
        No.[6]: !

        $ClipboardArray | foreach {$_.Gettype()}

        IsPublic IsSerial Name                                     BaseType                                                                                                            
        -------- -------- ----                                     --------                                                                                                            
        True     True     String                                   System.Object                                                                                                       
        True     True     DateTime                                 System.ValueType                                                                                                    
        True     True     Int32                                    System.ValueType                                                                                                    
        True     True     Int64                                    System.ValueType                                                                                                    
        True     True     Boolean                                  System.ValueType                                                                                                    
        True     True     String                                   System.Object              



        The exlamationmark will close the loop from importing anything more.
        The input to will be saved to the variable ClipboardArray.
        This example will try to convert every object in the array to all avaiable data types. If its not possible it will default back to System.String.
        The order for the data type convertion is [System.DateTime], [System.Int32], [System.Int64], [System.Boolean], [System.String].
        Array object 0 is a String, object 1 is a DateTime, object 2 is a Int32, object 3 is a Int64, object 4 is a Boolean and object 5 is a String.
        The EndChar parameter can be used when the input contains empty rows.
            
        .NOTES
        Created on:     2017-04-16 21:59
        Created by:     Philip Haglund
        Organization:   Gonjer.com
        Filename:       Read-ClipboardArray.ps1
        Version:        1.0.0.0
        Requirements:   Powershell 3.0
                        
        .INPUTS
        System.String

        .LINK
        https://gonjer.com
        https://github.com/PhilipHaglund
    #> 
[CmdletBinding(
    HelpUri = 'https://github.com/PhilipHaglund/PowerShell/tree/master/Read-ClipboardArray',
    PositionalBinding = $false,
    DefaultParameterSetName = 'Default'
)]
[Alias('rca')]
param (
    [Parameter(
        ParameterSetName = 'Default'
    )]
    [ValidateSet('All', 'DateTime', 'Int32', 'Int64', 'Boolean', 'String')]
    [Alias('D')]
    [string[]]$DataType = 'String',

    [Parameter(
        ParameterSetName = 'Default'
    )]
    [Alias('E')]
    [string]$EndChar = ''
)

    begin
    {
        if (($DataType = $DataType | Sort-Object -Unique).Count -gt 5 -or $DataType -eq 'All')
        {
            [string]$DataType = 'All'
        }

        New-Variable -Name ClipboardArray -Value @() -Scope Script -Force -Description 'Variable created from Read-ClipboardArray.'
        [uint32]$n = 0

        function Convert-Object
        {
            <#
                .SYNOPSIS
                Simple inline function to convert strings to other object types.
            #>
            [CmdletBinding()]
            [OutputType('System.String', 'System.DateTime', 'System.Int32', 'System.Int64', 'System.Boolean')]
            param (
                [Parameter(
                    ValueFromPipeline = $true
                )]
                [AllowNull()]
                [string]$InputObject
            )
            process
            {
                switch ($DataType)
                {
                    DateTime
                    {
                        try
                        {
                            Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,$DataType)
                            [Convert]::ToDateTime($InputObject)
                        }
                        catch
                        {
                            [string]$InputObject
                        }
                    }
                    Int32
                    {
                        
                        try
                        {
                            Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,$DataType)
                            [Convert]::ToInt32($InputObject)
                        }
                        catch
                        {
                            [string]$InputObject
                        }
                    }
                    Int64
                    {
                        
                        try
                        {
                            Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,$DataType)
                            [Convert]::ToInt64($InputObject)
                        }
                        catch
                        {
                            [string]$InputObject
                        }
                    }
                    Boolean
                    {
                        
                        try
                        {
                            Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,$DataType)
                            [Convert]::ToBoolean($InputObject)
                        }
                        catch
                        {
                            [string]$InputObject
                        }
                    }
                    All
                    {
                        try
                        {
                            Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,'DateTime')
                            [Convert]::ToDateTime($InputObject)
                        }
                        catch
                        {
                            try
                            {
                                Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,'Int32')
                                [Convert]::ToInt32($InputObject)
                            }
                            catch
                            {
                                try
                                {
                                    Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,'Int64')
                                    [Convert]::ToInt64($InputObject)
                                }
                                catch
                                {
                                    try
                                    {
                                        Write-Verbose -Message ('Trying to convert {0} to {1}' -f $InputObject,'Boolean')
                                        [Convert]::ToBoolean($InputObject)
                                    }
                                    catch
                                    {
                                        [string]$InputObject
                                    }
                                }
                            }
                        }
                    }
                    Default
                    {
                        [string]$InputObject
                    }

                }
            }
        }
    }
    process
    {
        do 
        {
            $Input = (Read-Host -Prompt "No.[$($n)]")
            $n++
        
            if ($Input -ne $EndChar) 
            {
                $script:ClipboardArray += $Input | Convert-Object
            }
        }
        until ($Input -eq $EndChar)
    }
    end
    {
        Write-Verbose -Message 'Enter $ClipboardArray to access the pasted array objects'
    }
}

