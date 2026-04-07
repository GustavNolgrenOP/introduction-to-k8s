# Setup

Detta steg kan göras antingen "för hand" eller genom att köra `Vagrantfile` som kommer skapa våra tre VM:ar automatiskt med Almalinux 9 installerat. FÖr att göra det, se till att du har `vagrant` installerat i din Windows PowerShell.

## Virtuell Switch

Innan du skapar upp VM:arna måste vi skapa ett sätt för dem att kommunicera med varandra. Vi kommer därför skapa en virtuell switch, kör dessa kommandom i en PowerShell-terminal som administrator:

```powershell
New-VMSwitch -Name "k8s-switch" -SwitchType Internal

# Hämta index för adapter
Get-NetAdapter

# Assigna en IP till värden på switchen (ersätt InterfaceIndex med det du fick i tidigare steg)
New-NetIPAddress -IPAddress 192.168.100.1 -PrefixLength 24 -InterfaceIndex <index>

# Skapa en NAT så VM:arna kan nå internet
New-NetNat -Name "k8s-nat" -InternalIPInterfaceAddressPrefix 192.168.100.0/24
```

## Skapa VM:ar med vagrant

Beroende på hur mycket minne din dator har kan du behöva skala ner på antalet noder (alltså maskiner). Jag har en dator med 32 GB minne och kan då köra tre VM:ar med 4 GB minne, men har du lägre kan du behöva skala ner till en eller två.

Om du vill skapa VM:arna med vagrant kan du göra det nu. Se då till att köra `vagrant up` i en PowerShell-terminal som administrator. Detta kan ta några minuter, men när allt är färdigt kan du

## Skapa VM:ar manuellt

Då denna del är lite mer tidskrävande än vagrant kommer du antagligen inte ha tid att göra det under workshopens tid. Vill du göra den ändå kan du kolla på [de specifika instruktionerna](./manual-setup.md).

## Verifiera anslutning till maskinerna

Eftersom kommande steg är utformade att köra från WSL måste du verifiera att VM:arna du skapade nu kan nås. Med lösenordet `vagrant`, kör följande för att tre VM:ar (10, 11, 12):

```bash
ssh vagrant@192.168.100.1X

# I VM, pinga de andra:
ping 192.168.100.1X
```

**MEN** detta kommer inte fungera just nu! Eftersom WSL har sin egna interna NAT kommer vi inte kunna nå VM:arnas egna vi gjorde tidigare. Vi måste därför byta ut den mot `k8s-switch`.

**C:\Users\<User>\.wslconfig**:

```
[wsl2]
networkingMode=bridged
vmSwitch=k8s-switch

[network]
generateResolvConf=false
```

Starta sedan om din WSL genom:

```bash
windows:~$ wsl --shutdown
windows:~$ wsl
```

I WSL-terminalen måste du ge WSL en ip i samma subnet och en default route:

```bash
ubuntu:~$ sudo ip addr add 192.168.100.50/24 dev eth0
ubuntu:~$ sudo ip route add default via 192.168.100.1
```

Vill du ha en mer permanent lösning, lägg till följande i **/etc/wsl.conf**:

```
[boot]
command="ip addr add 192.168.100.50/24 dev eth0; ip route add default via 192.168.100.1"
```
