# 04 - Din egen app

Nu är det din tur. Målet med det här steget är att bygga en egen applikation, containerisera den, pusha den till registryn i klustret och driftsätta den.

Det finns inga färdiga manifest här — det är upp till dig.

## Steg att ta sig igenom

1. **Bygg din app** — Välj valfritt språk och ramverk. Det behöver inte vara avancerat; en enkel HTTP-server som svarar på anrop räcker.

2. **Skriv en Dockerfile** — Tänk på att hålla imagen liten. Utgå från en lämplig basimage för ditt språk.

3. **Skriv ett manifest** — Du behöver minst en Deployment och en Service. Fundera på om du vill exponera appen via en Ingress också.

4. **Driftsätt och verifiera** — Kontrollera att podden startar och att du kan nå appen.

##

En grej du borde göra innan du skapar din egna applikation är att sätta en "label" på en av dina noder. Detta gör så att vi i `registry.yaml` kan specificera vilken nod som kommer rymma vårt image, spelar det inte så stor roll för dig kan du ta bort denna bit:

```yaml
nodeSelector:
  registry: "true"
tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
```

Kör `kubectl label node k8s-master registry=true` om du vill specifiera nod för registry.

## Exempel

Använd gärna ett deploy script! Jag har en liten node.js applikation som skickar tillbaka hälsningar och för att lägga ut den på klustret använder jag detta script:

```shell
#!/bin/bash

REGISTRY="192.168.100.10:32000"
APP="greeting-app"
IMAGE="$REGISTRY/$APP"

# 1. Build
podman build -t $IMAGE:latest .

# 2. Push and capture digest
podman push $IMAGE:latest --digestfile digest.txt --tls-verify=false
DIGEST=$(cat digest.txt)
echo "Digest: $DIGEST"

# 3. Patch the deployment with the new digest
kubectl set image deployment/$APP \
  $APP=$IMAGE@$DIGEST

# 4. Watch the rollout
kubectl rollout status deployment/$APP

```
