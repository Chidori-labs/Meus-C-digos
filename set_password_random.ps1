<#
Desenvolido por Henrique Queiroz, em um dia como outro qualquer.
A ideia desse script era executar uma atividade em diversas maquinas ao mesmo tempo, para isso é utilizei start-job.
Esse codigo em questão realiza a alteração da senha do administrador local em lote, dessa forma é possivel executar essa atividade em diversos computadores ao mesmo tempo.
Cada maquina terá uma senha diferente.
#>

function CallJob ()
{
    $jobs=job | Select-Object State  | where-object {($_.State -eq 'Running')} | Measure-Object | Select-Object count # Verificando quantidade de jobs em execução antes de chamar outro.
    #$jobs.Count
    if ( $jobs.Count -lt $limite)
        {
            MakeJobRemotely  # Chamando o job.
        }
        else
        {
            write-host "Aguardando termino dos jobs" -ForegroundColor green
            sleep 10
            CallJob
        }
}  



function MakeJobRemotely ()
{
    echo "$remotePC;administrator;$pass" >>  "C:\administrators-password.csv"
    Start-Job -Name "$remotePC-ChangeAdminPass" -ScriptBlock  {
        invoke-Command -ComputerName $args[0] -ScriptBlock {
            $ErrorActionPreference = 'SilentlyContinue'
            $pass=$($args[0])
            $args[0],$args[1] 
            net user administrator $pass /expires:never
            net user administrator  /EXPIRES:NEVER 
            wmic useraccount where "Name='administrator'" set PasswordExpires=false
            echo "$env:COMPUTERNAME senha = $pass" 
        } -argumentlist $args[1]  } -argumentlist $remotePC ,$pass 

}



function CheckChange 
{
Clear
$cont=0
$line = Get-Content "C:\computers.txt" | Measure-Object | findstr "Count" | Foreach{ $_.Split(" ",[StringSplitOptions]"RemoveEmptyEntries")[2] }  
do {
        $remotePC=Get-Content "C:\computers.txt" | Select-Object -Index $cont    
        Get-WmiObject -ComputerName $remotePC -Class Win32_UserAccount -Filter  "LocalAccount='True'" | Format-Table -AutoSize PSComputername, Name, Status, Disabled, AccountType, Lockout, PasswordRequired, PasswordChangeable, SID
        $cont++
} while($cont -lt $line)
}


clear
$cont=0
$limite=70 #Valor maximo de jobs em execução
$line = Get-Content "C:\computers.txt" | Measure-Object | Select-Object count
do {
    $pass=-join ((33..126) |  Get-Random -Count 12|  % {[char]$_}) | foreach {$_.replace('"',"#")} | foreach {$_.replace("'","@")}  | foreach {$_.replace("~","&")} | foreach {$_.replace(";",":")} | foreach {$_.replace("%","!")} # Gerando senha aleatoria.
    $remotePC=Get-Content "C:\computers.txt" | Select-Object -Index $cont    
    CallJob
    $cont++
} while($cont -lt $line.Count)
