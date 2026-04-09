# Images och Secrets

I denna del ska vi hämta ner images från Docker Hub och deploya dem till vårt kluster. Dessutom kommer vi lära oss hur man hanterar känslig konfiguration med Kubernetes Secrets.

## Begrepp

| Begrepp          | Vad det är                                                                                      |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| **Image**        | En oföränderlig mall för en container, byggd med t.ex. Docker och lagrad i ett register         |
| **Secret**       | En Kubernetes-resurs för att lagra känslig data (lösenord, tokens) separat från manifestet      |
| **secretKeyRef** | Referens i ett manifest som hämtar ett värde från en Secret och injicerar det som miljövariabel |

---

## Innehåll

- `manifests/busybox.yaml` — En enkel BusyBox-pod för felsökning
- `manifests/postgresql.yaml` — PostgreSQL med inloggningsuppgifter från en Secret

---

## BusyBox

BusyBox är en liten container med vanliga Unix-verktyg. Den är perfekt för att felsöka nätverksproblem, DNS och tjänster inne i klustret.

### Deploya

```bash
kubectl apply -f manifests/busybox.yaml
```

### Använd

```bash
kubectl exec -it deploy/busybox -- sh
```

Inuti containern kan du t.ex.:

```sh
nslookup postgresql       # testa DNS
wget -qO- http://postgresql:5432  # testa nätverksåtkomst
ping 8.8.8.8              # testa extern anslutning
```

---

## PostgreSQL med Secrets

Istället för att hårdkoda inloggningsuppgifter i manifestet använder vi en Kubernetes Secret.

### Skapa Secret

```bash
kubectl create secret generic postgresql-secret \
  --from-literal=username=admin \
  --from-literal=password=yourpassword \
  --from-literal=database=mydb
```

### Deploya

```bash
kubectl apply -f manifests/postgresql.yaml
```

### Anslut

```bash
kubectl exec -it deploy/postgresql -- psql -U admin -d mydb
```

---

## Städa upp

```bash
kubectl delete -f manifests/busybox.yaml
kubectl delete -f manifests/postgresql.yaml
kubectl delete secret postgresql-secret
```
