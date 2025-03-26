# devsecops-se-onboarding

## Fork and Clone this Repo

## Clone to Desktop and VM

## NodeJS Microservice - Docker Image -
`docker build -t plusone-app .`

`docker run -p 5001:5000 plusone-app`

`curl localhost:8787/plusone/99`
 
## NodeJS Microservice - Kubernetes Deployment -
`kubectl create deploy node-app --image plusone-app`

`kubectl expose deploy node-app --name node-service --port 5000 --type ClusterIP`

`curl node-service-ip:5000/plusone/99`

## 🛡️ Git Hook: Pre-commit Secret Scanning

We use [pre-commit](https://pre-commit.com) + [Talisman](https://github.com/thoughtworks/talisman) to prevent committing secrets or sensitive info.

### 🧩 Setup (one-time)

```bash
brew install pre-commit       # or: pip install pre-commit
pre-commit install
pre-commit run --all-files    # optional: run on entire repo
