# 04 - Din egen app

Nu är det din tur. Målet med det här steget är att bygga en egen applikation, containerisera den, pusha den till registryn i klustret och driftsätta den.

Det finns inga färdiga manifest här — det är upp till dig.

## Registry

Registry körs på NodePort `32000`. Kom ihåg att konfigurera RKE2 att lita på det innan du försöker pusha eller pulla images.

## Steg att ta sig igenom

1. **Bygg din app** — Välj valfritt språk och ramverk. Det behöver inte vara avancerat; en enkel HTTP-server som svarar på anrop räcker.

2. **Skriv en Dockerfile** — Tänk på att hålla imagen liten. Utgå från en lämplig basimage för ditt språk.

3. **Bygg och pusha imagen** — Tagga imagen med registrys adress och pusha den dit.

4. **Skriv ett manifest** — Du behöver minst en Deployment och en Service. Fundera på om du vill exponera appen via en Ingress också.

5. **Driftsätt och verifiera** — Kontrollera att podden startar och att du kan nå appen.
