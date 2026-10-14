$utenti = Import-Csv C:\Script\utenti.csv

foreach ($u in $utenti) {
New-ADUser -Name "$($u.Nome) $($u.Cognome)" -SamAccountName $u.Username -Path "OU=$($u.Reparto),OU=Utenti,OU=Azienda,DC=lab,DC=local" -AccountPassword (ConvertTo-SecureString "Benvenuto2026!" -AsPlainText -Force) -Enabled $true
}
