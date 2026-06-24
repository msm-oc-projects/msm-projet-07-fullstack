# Déploiement K3s - Orion MicroCRM

Ce dossier fournit une cible Kubernetes légère avec K3s. Docker Compose reste utile pour le développement local et le livrable initial, mais K3s prépare une trajectoire plus proche des pratiques du marché.

## Prérequis

- K3s installé et démarré ;
- `kubectl` configuré ;
- images Docker `orion-microcrm-back:latest` et `orion-microcrm-front:latest` disponibles localement ou publiées dans le registre configuré.

## Vérifier le cluster

```bash
kubectl version --client
kubectl get nodes
kubectl get pods -A
```

## Construire les images localement

```bash
docker build --target back -t orion-microcrm-back:latest .
docker build --target front -t orion-microcrm-front:latest .
```

## Importer les images Docker dans K3s

K3s utilise containerd. Les images présentes dans Docker ne sont donc pas automatiquement visibles par K3s.

```bash
docker save orion-microcrm-back:latest | sudo k3s ctr images import -
docker save orion-microcrm-front:latest | sudo k3s ctr images import -
sudo k3s ctr images ls | grep orion-microcrm
```

## Déployer l'application

```bash
kubectl apply -k k8s
kubectl -n orion-microcrm rollout status deployment/back
kubectl -n orion-microcrm rollout status deployment/front
kubectl -n orion-microcrm get pods,svc,ingress
```

Ajoutez l'entrée locale suivante si l'Ingress Traefik de K3s est utilisé :

```bash
echo "127.0.0.1 microcrm.local" | sudo tee -a /etc/hosts
curl --fail http://microcrm.local/
curl --fail http://microcrm.local/api/persons
```

Alternative sans modifier `/etc/hosts` :

```bash
kubectl -n orion-microcrm port-forward svc/front 8088:8080
curl --fail http://localhost:8088/
curl --fail http://localhost:8088/api/persons
```

## Utiliser les images du registre

Le registre est paramétrable. GHCR reste le choix par défaut, mais les commandes fonctionnent avec un autre registre.

```bash
kubectl -n orion-microcrm set image deployment/back back=<registry>/<namespace>/orion-microcrm-back:<tag>
kubectl -n orion-microcrm set image deployment/front front=<registry>/<namespace>/orion-microcrm-front:<tag>
kubectl -n orion-microcrm rollout status deployment/back
kubectl -n orion-microcrm rollout status deployment/front
```

Pour un registre privé :

```bash
kubectl -n orion-microcrm create secret docker-registry registry-credentials \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<token>

kubectl -n orion-microcrm patch serviceaccount default \
  -p '{"imagePullSecrets":[{"name":"registry-credentials"}]}'
```

## Commandes d'exploitation

```bash
kubectl -n orion-microcrm get all
kubectl -n orion-microcrm describe pod -l app.kubernetes.io/name=orion-microcrm
kubectl -n orion-microcrm logs deployment/back --tail=100
kubectl -n orion-microcrm logs deployment/front --tail=100
kubectl -n orion-microcrm rollout restart deployment/back
kubectl -n orion-microcrm rollout restart deployment/front
kubectl -n orion-microcrm rollout undo deployment/back
kubectl -n orion-microcrm rollout undo deployment/front
kubectl delete -k k8s
```

## Validation des manifests

```bash
kubectl kustomize k8s
kubectl apply -k k8s --dry-run=client
```
