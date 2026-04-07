# Ingress-kontroller & routing

Nu när klustret är uppe och du kan köra `kubectl` lokalt är det dags att exponera workloads. I Kubernetes används en **Ingress-kontroller** för att ta emot inkommande HTTP-trafik och routa den till rätt Service inuti klustret.

RKE2 levereras med **ingress-nginx** förinstallerat, så du behöver inte installera något extra.

---

## Begrepp

| Resurs                 | Vad det är                                                                |
| ---------------------- | ------------------------------------------------------------------------- |
| **Ingress-kontroller** | En pod som lyssnar på port 80/443 och agerar reverse proxy                |
| **Ingress**            | En Kubernetes-resurs som definierar routing-regler (host, path → Service) |
| **Service**            | Exponerar en grupp pods under ett stabilt DNS-namn inuti klustret         |

Trafikflödet ser ut så här:

```
Klient -> Ingress-kontroller (nginx) -> Service -> Pod(s)
```

---

## Steg 1 – Verifiera att ingress-nginx är igång

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=rke2-ingress-nginx
```

Du ska se en eller flera poddar med status `Running`. Du kan också kontrollera att nginx lyssnar på nodernas IP:er:

```bash
curl -I http://192.168.100.11
# Förväntat svar: HTTP/1.1 404 Not Found  (nginx svarar men har inga regler än)
```

---

## Steg 2 – Driftsätt testapplikation och Ingress

Vi skapar en Deployment med tre replicas av `ealen/echo-server`, en Service som pekar på dem, och en Ingress som definierar routing-regeln: _"trafik till `demo.k8s.local` ska skickas till echo-server på port 80"_.

En echo-server speglar tillbaka hela HTTP-requesten (headers, host, path) vilket gör det enkelt att se att routingen faktiskt fungerar.

```bash
kubectl apply -f manifests/
```

Verifiera att poddarna startar och att Ingress-resursen fått en adress:

```bash
kubectl get pods -l app=echo-server
kubectl get service echo-server
kubectl get ingress main-ingress
```

Under `ADDRESS` på Ingress ska du se en av nodernas IP:er (kan ta någon sekund).

---

## Steg 4 – Testa routing

Eftersom `demo.k8s.local` inte finns i DNS behöver vi hjälpa curl att lösa upp det:

```bash
curl --resolve demo.k8s.local:80:192.168.100.11 http://demo.k8s.local
```

Du ska få tillbaka ett JSON-svar med information om din request — host, headers, sökväg m.m. Det bekräftar att trafiken faktiskt routas hela vägen genom Ingress → Service → Pod.

Vill du slippa `--resolve` kan du lägga till en rad i `/etc/hosts`:

```
192.168.100.11  demo.k8s.local
```

Och sedan köra:

```bash
curl http://demo.k8s.local
```

---

## Steg 5 – Utforska

Testa gärna att:

- Skala upp eller ned antalet replicas och se att trafiken fortsätter fungera:

  ```bash
  kubectl scale deployment echo-server --replicas=4
  kubectl get pods -l app=echo-server
  ```

- Ta bort en pod och observera att Kubernetes startar om den:

  ```bash
  kubectl delete pod <pod-namn>
  kubectl get pods -l app=echo-server -w
  ```

- Lägga till en andra Ingress-regel med en annan `host` som pekar mot en annan Service.

---

## Rensa upp

```bash
kubectl delete -f manifests/
```

I nästa steg tittar vi på hur man hanterar konfiguration och hemligheter med **ConfigMaps** och **Secrets**.
