# Active Directory Password Weakening Tool 🔓

> **Complément essentiel à BadBlood pour créer des environnements AD réalistes et vulnérables**

Ce script PowerShell est conçu comme un complément à [BadBlood](https://github.com/davidprowe/BadBlood) pour fragiliser davantage un environnement Active Directory en remplaçant les mots de passe des utilisateurs par des mots de passe vulnérables issus de la célèbre liste rockyou.txt.

![AD Vulnerability Demo](https://via.placeholder.com/800x400.png?text=AD+Vulnerability+Simulation) *Exemple visuel d'un environnement AD fragilisé*

## 🎯 Objectifs Principaux

- **Fragiliser l'AD** : Remplacer les mots de passe existants par des mots de passe connus et crackables
- **Simuler des mauvaises pratiques** : Recréer des comportements à risque comme les mots de passe dans les descriptions
- **Créer un lab réaliste** : Préparer un environnement AD vulnérable pour :
  - Exercices de pentest
  - Simulations de forensic
  - Démonstrations de vulnérabilités AD
  - Entraînement aux attaques credential-based
- **Identifier les risques** : Faciliter la démonstration des failles de sécurité courantes dans les AD

## ✨ Fonctionnalités Clés

| Fonctionnalité | Description | 
|----------------|-------------|
| 🔄 Changement de mots de passe | Automatise le changement pour tous les utilisateurs AD actifs |
| 📚 Source rockyou.txt | Utilise exclusivement des mots de passe de la célèbre liste |
| 🛡️ Politique de complexité | Respecte les règles (12+ caractères, 3 types différents) |
| ⚠️ Détection de risques | Identifie les mots de passe dans les descriptions |
| 📊 Reporting complet | Génère des logs détaillés et rapports CSV |
| ⏱️ Barre de progression | Visualisation en temps réel de l'avancement |

## 📋 Prérequis

1. **Environnement Active Directory** avec module PowerShell AD installé
2. **Liste rockyou.txt** - Disponible dans Kali Linux ou sur [SecLists](https://github.com/danielmiessler/SecLists)
3. **Permissions** : Compte avec droits d'administrateur de domaine
4. **PowerShell 5.1+** avec politique d'exécution appropriée

## ⚙️ Configuration Rapide

1. Copiez le script PowerShell sur un contrôleur de domaine
2. Placez `rockyou.txt` dans un chemin accessible (ex: `C:\rockyou.txt`)
3. Modifiez les variables en tête du script si nécessaire :

```powershell
# Configuration
$rockyouPath = "C:\chemin\vers\rockyou.txt"
$skipUsers = @("Administrateur", "Invité", "krbtgt", "DefaultAccount")
$passwordPhrase = "password is" # Phrase à détecter dans les descriptions
```
## ❓ Pourquoi ce Script?

Ce projet comble une lacune importante dans les outils de préparation d'environnements AD vulnérables :

BadBlood crée une structure AD réaliste mais avec des mots de passe forts
Ce script fragilise l'AD en appliquant des mots de passe faibles et connus
Résultat : Environnement parfait pour tester :
  - Attaques par force brute
  - Credential stuffing
  - Kerberoasting
  - Pass-the-hash

## 📜 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](https://github.com/PCF-bma/ChangePWD_BadBlood/blob/main/LICENSE) pour plus de détails.

