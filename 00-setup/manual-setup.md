# Steg 1 - Skapa 3 VM:ar

Inför detta steg måste du hämta ner ett ISO image för ditt distro of-choice. Instruktionerna använder sig av [Ubuntu Server](https://ubuntu.com/download/server), men du kan använda dig av någon annan du är bekväm med. Notera att instruktionerna då kan skilja sig!

Lägg imagen i lämplig mapp på din dator, jag lade min i **C:\ISOs**.

Kör sedan powershell-scriptet i detta repo: **vm-create-script.ps1**. Denna kommer starta upp maskinerna med och går att hitta i _Hyper-V Manager_ om du kör den som administratör.

Skulle något gå fel, finns det också ett till script: **stop-and-remove-vms.ps1**. Kör denna, men om dina VM:ar fortfarande är igång brukar en omstart av din dator fungera, givet att du exekverar scriptet igen.

**OBS:** När alla VM:ar är igång måste du genomföra steg 3-5 för samtliga maskiner. Gå sedan till steg 6.

# Steg 2 - Installera operativsystemen

I Hyper-V manager borde du nu kunna se och komma åt alla tre maskiner genom UI:t. Vi vill inte konfigurera nätverksbiten riktigt än, så skippa det steget i installationen. Stegen borde se ut som följande om du kör Ubuntu:

1. Välj Engelska som språk
2. Välj tangentbordslayout
3. Installationstyp, välj not minimized. Kanske fungerar med minimized, men gör det på egen risk
4. Nätverk: skippa
5. Proxy: skippa
6. Mirror: Default
7. Storage -> Use entire disk, alltså de 20GB vi gav VM:en
8. Profil (här kan du egentligen välja vad som):
   - Name: **ubuntu**
   - Server-name (Samma namn som maskinens): **k8s-master**, **k8s-worker1**, eller **k8s-worker2**
   - Användarnamn: **ubuntu**
   - Lösenord: Ta något du kommer ihåg
9. SSH -> **Install OpenSSH Server**
10. Snaps: Skippa
11. Vänta på allt att installeras och reboota

# Steg 3 - Sätt statisk IP efter reboot

Kolla om det finns en existerande netplan:

```bash
ls /etc/netplan
```

Eftersom vi inte konfigurerade nätverk i förra steget borde inte det finna någon här, men oavsett om den finns eller inte ska vi ersätta den.

Skapa **/etc/netplan/00-installer-config.yaml** och gå och ersätt all text med:

För master-noden kommer adressen vara **192.168.100.10/24**, för worker1 och worker2 kommer det vara **192.168.100.11/24** respektive **192.168.100.12/24**.

```yaml
network:
  ethernets:
    eth0:
      addresses: [192.168.100.10/24]
      routes:
        - to: default
          via: 192.168.100.1
      nameservers:
        addresses: [8.8.8.8]
  version: 2
```

Sedan:

```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan apply
```

Verifiera genom att pinga internet:

```bash
ping 8.8.8.8
```

# Steg 4 - Set hostname och lägg till noder

```bash
sudo apt update && sudo apt upgrade -y
hostnamectl set-hostname k8s-master # Ändra beroende på VM
```

Sen vill vi också lägga in noderna så de kan hitta varandra efter namn

```bash
sudo vi /etc/hosts
```

Längst ner i denna fil lägg till de andra adresserna och namn:

```
192.168.100.10 k8s-master
192.168.100.11 k8s-worker1
192.168.100.12 k8s-worker2
```

# Steg 5 - Kontrollera att maskinerna kan nå varandra

När steg 3-5 är färdiga kan du i en av dina VM:ar testa pinga någon av de andra två.

```bash
ping k8s-master
ping k8s-worker1
ping k8s-worker2
```

Skulle detta inte fungera har något gått fel. Kontrollera att du följt instruktionerna, om inte det fungerar är Claude din bästa vän!

# Steg 6 - Avaktivera dynamiskt minne

Då kubernetes och RKE2 inte fungerar särskilt bra med dynamiskt minne aktiverat (alltså att det vi gett i minne går över till hårddisk om den går över), så måste detta stängas av. Detta görs bäst genom att du stoppar alla tre VM:ar, öppnar inställningar för varje maskin i Hyper-V och stänger av dynamiskt minne där.
