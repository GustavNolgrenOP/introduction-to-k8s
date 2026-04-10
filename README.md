# Introduktion till Kubernetes

En praktisk introduktionskurs i Kubernetes med Rancher Kubernetes Enginge (RKE2).

---

## Översikt

Kursen täcker Kubernetes grundläggande koncept och ger deltagarna praktisk erfarenhet av att driftsätta och hantera workloads i ett kluster. Kursen kommer vara utformad från att du använder Windows med WSL (Windows Subsystem for Linux). Det leder till lite fler extra steg än om du kör native linux när vi skapar upp VM:arna, men alla de stegen finns i detta repo under `00-setup` och dessutom en automatisering med vagrant man kan köra.

---

## Innehåll

| #   | Modulbranch                                                | Ämne                                                |
| --- | ---------------------------------------------------------- | --------------------------------------------------- |
| 0   | [00-setup](./00-setup/README.md)                           | Verktyg, förberedande arbete                        |
| 1   | [01-rke2](./01-rke2/README.md)                             | Uppstart av RKE2 och skapande av kluster            |
| 2   | [02-ingress](./02-ingress/README.md)                       | Ingress-kontroller, routing, Deployment och Service |
| 3   | [03-images-and-secrets](./03-images-and-secrets/README.md) | Images & Secrets                                    |
| 4   | [04-your-app](./04-your-app/README.md)                     | Resursgränser & driftsättningar                     |

---

## Program att installera

Se till att du har följande installerat innan sessionen:

- Docker eller Podman (WSL)
- [kubectl (WSL)](https://kubernetes.io/docs/tasks/tools/)
- [ansible (WSL)](https://docs.ansible.com/projects/ansible/latest/installation_guide/installation_distros.html)
- [vagrant (Windows)](https://winstall.app/apps/Hashicorp.Vagrant)

---

## Dokumentation

- [Kubernetes officiell dokumentation](https://kubernetes.io/docs/home/)
- [Interaktiv tutorial (kubernetes.io)](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [kubectl-lathund](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
