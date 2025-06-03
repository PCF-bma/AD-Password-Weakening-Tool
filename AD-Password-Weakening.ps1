# Configuration
$rockyouPath = "C:\Users\Administrateur\Desktop\rockyou.txt"
$skipUsers = @("Administrateur", "Invité", "krbtgt", "DefaultAccount") # Comptes à ignorer
$passwordPhrase = "password is" # Phrase à rechercher dans les descriptions
$logFile = "C:\Users\Administrateur\Desktop\PasswordReset_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Vérification du fichier rockyou
if (-not (Test-Path $rockyouPath)) {
    Write-Error "Fichier rockyou.txt introuvable!" 
    exit
}

# Charger le module AD
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "Module ActiveDirectory non disponible : $_"
    exit
}

# 1. Filtrer les mots de passe valides (12+ caractères, 3 types)
$validPasswords = [System.Collections.Generic.List[string]]::new()
$regex = @(
    '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{12,}$',      # Maj+min+chiffre
    '^(?=.*[A-Z])(?=.*[a-z])(?=.*[\W_]).{12,}$',   # Maj+min+spécial
    '^(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{12,}$',      # Maj+chiffre+spécial
    '^(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{12,}$'       # Min+chiffre+spécial
)

Get-Content $rockyouPath | ForEach-Object {
    $pwd = $_.Trim()
    if ($pwd.Length -ge 12) {
        foreach ($pattern in $regex) {
            if ($pwd -match $pattern) {
                $validPasswords.Add($pwd)
                break
            }
        }
    }
}

if ($validPasswords.Count -eq 0) {
    Write-Error "Aucun mot de passe valide dans rockyou.txt!"
    exit
}

# 2. Récupération des utilisateurs AD
$users = Get-ADUser -Filter * -Properties Description, Enabled | Where-Object {$_.Enabled}
$totalUsers = $users.Count
$processed = 0
$skipped = 0
$random = New-Object System.Random
$results = [System.Collections.Generic.List[PSObject]]::new()

# Démarrer le journal
"================================================
DÉMARRAGE DU SCRIPT : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Utilisateurs à traiter : $totalUsers
================================================" | Out-File -FilePath $logFile

foreach ($user in $users) {
    $samAccount = $user.SamAccountName
    $description = if ($null -ne $user.Description) { $user.Description } else { "" }  # Handle null description
    
    # Vérifier les comptes à ignorer
    if ($skipUsers -contains $samAccount) {
        $msg = "IGNORÉ : $samAccount (compte protégé)"
        Write-Host $msg -ForegroundColor DarkGray
        $results.Add([PSCustomObject]@{
            Compte = $samAccount
            Statut = "Ignoré (compte protégé)"
            MotDePasse = ""
        })
        $skipped++
        $msg | Out-File -FilePath $logFile -Append
        continue
    }
    
    # Vérifier la présence de la phrase dans la description
    if ($description -imatch [regex]::Escape($passwordPhrase)) {
        $msg = "IGNORÉ : $samAccount (mot de passe dans la description)"
        Write-Host $msg -ForegroundColor DarkYellow
        $results.Add([PSCustomObject]@{
            Compte = $samAccount
            Statut = "Ignoré (password in description)"
            MotDePasse = ""
        })
        $skipped++
        $msg | Out-File -FilePath $logFile -Append
        continue
    }

    try {
        # Générer nouveau mot de passe
        $newPassword = $validPasswords[$random.Next(0, $validPasswords.Count)]
        $securePass = ConvertTo-SecureString $newPassword -AsPlainText -Force

        # Appliquer les changements
        Set-ADAccountPassword -Identity $samAccount -NewPassword $securePass -Reset
        Set-ADUser -Identity $samAccount -ChangePasswordAtLogon $true

        # Ajouter au rapport
        $results.Add([PSCustomObject]@{
            Compte = $samAccount
            Statut = "Succès"
            MotDePasse = $newPassword
        })
        
        $msg = "SUCCÈS : Mot de passe modifié pour $samAccount"
        Write-Host $msg -ForegroundColor Green
        $msg | Out-File -FilePath $logFile -Append
    }
    catch {
        $errorMsg = $_.Exception.Message
        $msg = "ERREUR : $samAccount - $errorMsg"
        Write-Host $msg -ForegroundColor Red
        $results.Add([PSCustomObject]@{
            Compte = $samAccount
            Statut = "Erreur: $errorMsg"
            MotDePasse = ""
        })
        $msg | Out-File -FilePath $logFile -Append
    }
    finally {
        $processed++
        $progress = ($processed / $totalUsers) * 100
        Write-Progress -Activity "Traitement des comptes" -Status "$processed/$totalUsers utilisateurs" -PercentComplete $progress
    }
}

# 3. Génération du rapport final
$reportDate = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = "C:\Users\Administrateur\Desktop\PasswordReset_Report_$reportDate.csv"
$results | Export-Csv -Path $reportPath -NoTypeInformation -Delimiter ";" -Encoding UTF8

# Résumé
$summary = @"
================================================
RÉSUMÉ DE L'OPÉRATION
Date d'exécution     : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Utilisateurs traités : $($processed - $skipped)
Comptes ignorés      : $skipped
   - Comptes protégés : $($skipUsers.Count)
   - Password dans description : $($skipped - $skipUsers.Count)
Rapport généré       : $reportPath
Journal complet      : $logFile
================================================
"@

$summary | Out-File -FilePath $logFile -Append
Write-Host $summary -ForegroundColor Cyan
