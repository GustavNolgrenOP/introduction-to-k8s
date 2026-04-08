# RKE2 på VM:arna

RKE2 (Rancher Kubernetes Engine 2) är en säker och produktionsanpassad distribution av Kubernetes som utvecklas av SUSE via Rancher.

Den är designad för miljöer med höga säkerhetskrav, som företag, myndigheter och on-prem-installationer.

Viktiga punkter:

- Säkerhetsfokuserad med hårdare standardinställningar
- Förenklad installation och drift
- Använder containerd istället för Docker
- Lämplig för produktion och reglerade miljöer

Kort sagt: RKE2 är en mer säker och färdigpaketerad version av Kubernetes för seriösa produktionsmiljöer och nu ska du få möjligheten att installera det på dina VM:ar!

## Begrepp

| Begrepp        | Vad det är                                                                                    |
| -------------- | --------------------------------------------------------------------------------------------- |
| **RKE2**       | Rancher Kubernetes Engine 2 — en säkerhetsfokuserad Kubernetes-distribution från SUSE/Rancher |
| **Master-nod** | Noden som kör kontrollplanet (API-server, etcd, scheduler) och styr klustret                  |
| **Worker-nod** | Nod som kör applikationernas pods under masternodens styrning                                 |
| **etcd**       | Distribuerad nyckel-värde-databas som lagrar hela klustrets tillstånd                         |
| **containerd** | Container-runtime som RKE2 använder för att köra containers (istället för Docker)             |
| **kubeconfig** | Konfigurationsfil som talar om för `kubectl` hur det ska ansluta till klustret                |
| **kubectl**    | Kommandoradsverktyg för att interagera med ett Kubernetes-kluster                             |
| **Ansible**    | Automatiseringsverktyg som kör uppgifter på fjärrmaskiner via SSH utan att kräva agent        |
| **SELinux**    | Säkerhetsmodul i Linux-kärnan som begränsar vad processer och containers får göra             |

---

Likt det förra steget finns också ett automatiserat sätt att installera och skapa klustret. Detta görs med `ansible`, vilket är ett automatiseringsverktyg som låter oss skapa vårt RKE2 cluster snabbt. Om tiden är knapp och du vill få allting på plats, kör detta i WSL:

```bash
ansible-playbook -i inventory.ini site.yml
```

Annars kan du göra följande steg som motsvarar det som ansible gör.

## 01-system-prep.yml

Det här steget förbereder **alla noder** (master + workers) för att kunna köra Kubernetes. Det behöver göras på varje nod.

### Vad det gör

1. **Stänger av swap** — Kubernetes kräver att swap är inaktiverat, annars vägrar kubelet att starta. Swap stängs av direkt (`swapoff -a`) och kommenteras bort i `/etc/fstab` så att det inte aktiveras igen efter omstart.

2. **Laddar kernel-moduler** — Kubernetes nätverksstacken behöver två moduler:
   - `overlay` — används av containerd för lagersystem
   - `br_netfilter` — låter kernel-brandväggen se trafik som passerar genom nätverksbryggor

   Modulerna laddas direkt och sparas i `/etc/modules-load.d/k8s.conf` så de laddas automatiskt vid omstart.

3. **Konfigurerar sysctl-parametrar** — Tre nätverksinställningar sätts i `/etc/sysctl.d/k8s.conf`:
   - `net.bridge.bridge-nf-call-iptables = 1`
   - `net.bridge.bridge-nf-call-ip6tables = 1`
   - `net.ipv4.ip_forward = 1`

   Dessa är nödvändiga för att Pod-trafik ska kunna routas korrekt mellan noder. Inställningarna aktiveras direkt med `sysctl --system`.

### Manuella kommandon (motsvarar playbooken)

Kör följande på **varje nod** (master, worker1, worker2):

```bash
# Stäng av swap
sudo swapoff -a
sudo sed -i 's/^\([^#].*\sswap\s.*\)$/# \1/' /etc/fstab

# Ladda kernel-moduler
sudo modprobe overlay
sudo modprobe br_netfilter

# Gör modulerna persistenta
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Sätt sysctl-parametrar
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Verifiera att swap är av
swapon --show   # ska inte ge någon utdata
```

---

## 02-rke2-master.yml

Det här steget installerar och startar **RKE2 server** på masternoden (`k8s-master`, IP `192.168.100.10`). Masternoden måste vara klar innan workers kan ansluta.

### Vad det gör

1. **Skapar konfigurationskatalog** — `/etc/rancher/rke2/` skapas om den inte finns.

2. **Konfigurerar registry-spegling** — En `registries.yaml` skrivs som pekar om det interna Docker-registret (`192.168.100.10:32000`) till en HTTP-endpoint (utan TLS). Det är nödvändigt för att kunna dra images från ett lokalt osäkert register.

3. **Skriver master-konfiguration** — `config.yaml` sätter ett delat kluster-token och lägger till masternodens IP och hostname som giltiga TLS-SAN (Subject Alternative Names) i certifikaten.

4. **Installerar RKE2** — Kör det officiella installationsskriptet från `https://get.rke2.io`.

5. **Startar RKE2-tjänsten** — Aktiverar och startar `rke2-server` via systemd.

6. **Väntar tills klustret är redo** — Kontrollerar att port `9345` (RKE2 join-port) är öppen och att `rke2.yaml` (kubeconfig) har genererats.

7. **Korrigerar kubeconfig-adressen** — Den genererade kubeconfigen pekar på `127.0.0.1`; playbooken ersätter det med masternodens riktiga IP (`192.168.100.10`) så att den går att använda utifrån.

8. **Verifierar att noden är Ready** — Väntar tills `kubectl get node k8s-master` visar `Ready`.

### Manuella kommandon (kör på masternoden)

```bash
# Skapa konfigurationskatalog
sudo mkdir -p /etc/rancher/rke2

# Skriv registry-konfiguration
cat <<EOF | sudo tee /etc/rancher/rke2/registries.yaml
mirrors:
  "192.168.100.10:32000":
    endpoint:
      - "http://192.168.100.10:32000"
EOF

# Skriv master-konfiguration
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
token: my-shared-secret
tls-san:
  - 192.168.100.10
  - k8s-master
EOF

# Ladda ner och installera RKE2
curl -sfL https://get.rke2.io | sudo sh -

# Aktivera och starta tjänsten
sudo systemctl enable --now rke2-server

# Vänta tills kubeconfig har skapats (kan ta 1-2 minuter)
sudo ls /etc/rancher/rke2/rke2.yaml

# Korrigera adressen i kubeconfigen
sudo sed -i 's|https://127.0.0.1:6443|https://192.168.100.10:6443|' \
  /etc/rancher/rke2/rke2.yaml

# Verifiera att masternoden är Ready
sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  get nodes
```

---

## 03-rke2-workers.yml

Det här steget ansluter **worker-noderna** (`k8s-worker1`, `k8s-worker2`) till klustret. Noderna ansluts **en i taget** för att inte riskera problem med etcd-kvorumet.

> **Viktigt:** Kör inte detta steget förrän `02-rke2-master.yml` har slutförts!

### Vad det gör

1. **Skapar konfigurationskatalog** och **registry-konfiguration** — Precis som på masternoden.

2. **Skriver worker-konfiguration** — `config.yaml` på varje worker innehåller adressen till masternodens join-port (`9345`) och samma delade token som masternoden.

3. **Installerar och startar RKE2** — Samma installationsskript som på masternoden. På workers startar tjänsten också som `rke2-server` (RKE2 kör server-läge även på workers i ett HA-upplägg).

4. **Väntar tills noden är Ready** — Kör `kubectl get node <hostname>` från masternoden och väntar på `Ready`-status.

5. **Visar klusterstatus** — Efter att alla workers är klara skrivs en lista med alla noder ut.

### Manuella kommandon (kör på varje worker, en i taget)

```bash
# Skapa konfigurationskatalog
sudo mkdir -p /etc/rancher/rke2

# Skriv registry-konfiguration (samma som masternoden)
cat <<EOF | sudo tee /etc/rancher/rke2/registries.yaml
mirrors:
  "192.168.100.10:32000":
    endpoint:
      - "http://192.168.100.10:32000"
EOF

# Skriv worker-konfiguration
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
server: https://192.168.100.10:9345
token: my-shared-secret
EOF

# Ladda ner och installera RKE2
curl -sfL https://get.rke2.io | sudo sh -

# Aktivera och starta tjänsten
sudo systemctl enable --now rke2-server
```

Verifiera från **masternoden** att workern har anslutit:

```bash
sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  get nodes
```

Upprepa för nästa worker när den första visar `Ready`.

---

## 04-fetch-kubeconfig.yml

Det här steget hämtar kubeconfigen från masternoden och sparar den lokalt i WSL, så att du kan köra `kubectl` direkt från din lokala terminal utan att SSH:a in på masternoden.

### Vad det gör

1. **Läser kubeconfigen** från `/etc/rancher/rke2/rke2.yaml` på masternoden.

2. **Skapar katalogen** `~/.kube/configs/` lokalt om den inte finns (med restriktiva rättigheter, `0700`).

3. **Sparar kubeconfigen** till `~/.kube/configs/rke2-cluster.yaml` lokalt och ersätter samtidigt `127.0.0.1` med masternodens riktiga IP (`192.168.100.10`) så att filen fungerar utifrån. Filen sparas med rättigheten `0600` (enbart ägaren kan läsa).

4. **Verifierar** att `kubectl get nodes` fungerar lokalt med den hämtade kubeconfigen.

### Manuella kommandon (kör från WSL)

```bash
# Skapa lokal katalog
mkdir -p ~/.kube/configs
chmod 700 ~/.kube/configs

# Hämta och korrigera kubeconfigen
ssh vagrant@192.168.100.10 \
  "sudo cat /etc/rancher/rke2/rke2.yaml" \
  | sed 's|https://127.0.0.1:6443|https://192.168.100.10:6443|' \
  > ~/.kube/configs/rke2-cluster.yaml

chmod 600 ~/.kube/configs/rke2-cluster.yaml

# Exportera och testa
export KUBECONFIG=~/.kube/configs/rke2-cluster.yaml
kubectl get nodes
```

Lägg gärna till `export KUBECONFIG`-raden i din `~/.bashrc` eller `~/.zshrc` så slipper du ange den varje gång.

---

## 05-configure-selinux.yml

Det här steget konfigurerar SELinux så att `local-path-provisioner` — RKE2:s inbyggda mekanism för dynamisk volymskapning — kan skriva till rätt katalog på noderna.

### Vad det gör

1. **Installerar `policycoreutils-python-utils`** — Paketet innehåller verktyget `semanage` som behövs för att hantera SELinux-kontexter.

2. **Skapar katalogen** `/opt/local-path-provisioner` med rättigheten `0777` på alla noder. Det är här `local-path-provisioner` skapar PersistentVolume-kataloger.

3. **Sätter SELinux-filkontext** — Tilldelar kontexten `container_file_t` till `/opt/local-path-provisioner` och allt dess innehåll. Det innebär att containers (som kör med SELinux aktiverat) har lov att läsa och skriva i den katalogen.

4. **Tillämpar kontexten** — Kör `restorecon -Rv` för att applicera den nya kontexten på befintliga filer i katalogen.

### Manuella kommandon (kör på **alla noder**)

```bash
# Installera semanage
sudo dnf install -y policycoreutils-python-utils

# Skapa katalogen
sudo mkdir -p /opt/local-path-provisioner
sudo chmod 0777 /opt/local-path-provisioner

# Sätt SELinux-filkontext
sudo semanage fcontext -a -t container_file_t \
  "/opt/local-path-provisioner(/.*)?"

# Applicera kontexten
sudo restorecon -Rv /opt/local-path-provisioner

# Verifiera
ls -Z /opt/local-path-provisioner
```

`ls -Z` ska nu visa `container_file_t` som kontext för katalogen.

Nu borde du kunna köra kubectl-kommandon från din lokala dator och se dina noder och poddar. I nästa steg ska vi ändra klustret så vi kan nå dessa!
