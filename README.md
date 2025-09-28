# Flask + AWS Demo

Minimal **Flask + SQLAlchemy + Postgres** app with:
- Local dev using **Docker Compose**
- CI/CD using **GitHub Actions**
- AWS infra using **Terraform** (ECR, ECS Fargate, RDS Postgres, VPC)
- Remote state in **S3 + DynamoDB**

---

## 🚀 Local Development

```bash
docker-compose up --build
```
- API: [http://localhost:8000](http://localhost:8000)
- Endpoints:
  - `GET /` → Hello message
  - `GET /users` → list users
  - `POST /users` → add user `{ "name": "Alice" }`

---

## 🧪 Testing

```bash
pip install -r requirements.txt
pytest
```

---

## ⚡ Bootstrapping Remote State

Run once to create **S3 bucket + DynamoDB table**:

```bash
chmod +x scripts/setup-remote-state.sh
./scripts/setup-remote-state.sh
```

---

## 🌍 Terraform Deploy (Manual)

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

---

## ⚙️ GitHub Actions CI/CD

On push to `main`:
1. Lint (flake8)
2. Test (pytest)
3. Deploy:
   - Build & push Docker image to ECR
   - Run Terraform (ECS + RDS)

---

## 🔑 Environment Variables

Set in GitHub **Secrets**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

✅ Done! Push code → new version deploys automatically to AWS.
