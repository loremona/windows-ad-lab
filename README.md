# Windows AD Lab

Il mio laboratorio su Windows Server e Active Directory. Arrivo da Linux e volevo capire
come si gestisce un dominio Microsoft mettendoci le mani, non solo leggendo: così ho
costruito un piccolo dominio da zero in una macchina virtuale sul mio PC.

## Cosa ho fatto

**Rete e server**
- VM con Windows Server 2025 (Desktop Experience) su KVM/virt-manager
- Rete virtuale 192.168.122.0/24: ho ristretto il DHCP a .100–.254 per lasciare gli
  indirizzi bassi ai server con IP statico
- Server rinominato in `DC01`, IP statico `192.168.122.10`, DNS che punta a se stesso

**Active Directory**
- Ruolo AD DS installato e server promosso a primo Domain Controller della nuova foresta
  `lab.local`
- Verifica con `dcdiag` (nessun test fallito), `nslookup` e `Get-ADDomainController`

**OU e utenti**
```
lab.local
└── Azienda
    ├── Computer
    ├── Gruppi
    └── Utenti
        ├── IT
        └── Contabilita
```
Ho creato una struttura di OU mia invece di usare i container predefiniti `Users` e
`Computers`, perché ai container non si possono collegare GPO.

**Group Policy**
- GPO *Blocco pannello di controllo* collegata all'OU `Utenti`, quindi ereditata da IT e
  Contabilita. Verificata con Group Policy Modeling sull'utente `mrossi`.
- Lunghezza minima delle password portata a 12 caratteri nella **Default Domain Policy**:
  la password policy degli account di dominio funziona solo a livello di dominio, non
  su una OU. Verificata con `gpupdate /force`, `gpresult /r` e
  `Get-ADDefaultDomainPasswordPolicy`.

## Lo script: `crea-utenti.ps1`

Crea in blocco gli utenti elencati in un file CSV e mette ognuno nell'OU del suo
reparto.

Il CSV ha quattro colonne:

```
Nome,Cognome,Username,Reparto
Luca,Ferrari,lferrari,IT
```

Lo script legge il file con `Import-Csv`, che trasforma ogni riga in un oggetto, e con un
`foreach` crea un utente per ogni riga con `New-ADUser`. L'OU di destinazione viene
costruita dal campo `Reparto`, per esempio
`OU=IT,OU=Utenti,OU=Azienda,DC=lab,DC=local`.

Per usarlo, su un Domain Controller o su una macchina con il modulo ActiveDirectory:

```powershell
cd C:\Script
.\crea-utenti.ps1
```

## Cosa vorrei migliorare

- **Password:** ora la password iniziale è scritta nello script. Va bene per un lab, ma
  in produzione no. Il prossimo passo è chiederla con `Read-Host -AsSecureString`.
- **Utenti già esistenti:** se un username c'è già, `New-ADUser` dà errore. Vorrei
  controllarlo prima con `Get-ADUser` e saltare quell'utente.
- **Gruppi:** aggiungere ogni utente al gruppo del suo reparto con `Add-ADGroupMember`.
- **Seconda VM:** unire un server membro al dominio, per vedere le GPO applicate a un
  login vero e non solo simulate.
