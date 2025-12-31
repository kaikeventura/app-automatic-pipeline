# 📦 App Automatic Pipeline — ECS + Fargate Spot + Terraform

Projeto de referência para **deploy automatizado de uma API Java** na AWS usando **ECS Fargate Spot**, **Terraform (IaC)** e **GitHub Actions (OIDC)**, integrado com **RDS PostgreSQL**, **S3**, **SQS**, **Secrets Manager** e **CodeDeploy**, priorizando **baixo custo** e **boas práticas reais de produção**.

---

## 🧱 Arquitetura (Visão Geral)

Fluxo de ponta a ponta:

1. Código versionado no **GitHub**
2. Push na branch `main`
3. **GitHub Actions** assume role AWS via **OIDC**
4. Build da imagem Docker (**ARM64 / Graviton**)
5. Push para **Amazon ECR**
6. Registro de nova **ECS Task Definition**
7. Deploy **Blue/Green** via **AWS CodeDeploy**
8. Execução no **ECS Fargate Spot**
9. Exposição via **Application Load Balancer**
10. Persistência no **RDS PostgreSQL**
11. Credenciais no **AWS Secrets Manager**
12. Comunicação privada via **VPC Endpoints** (sem NAT Gateway)

Região: `us-east-1`

---

## 🛠️ Stack Utilizada

- Java API (Spring Boot / Quarkus)
- Docker (ARM64 / Graviton)
- Amazon ECS + Fargate Spot
- Application Load Balancer (ALB)
- Amazon RDS (PostgreSQL)
- Amazon S3
- Amazon SQS
- AWS Secrets Manager
- AWS CodeDeploy (ECS Blue/Green)
- Terraform
- GitHub Actions (OIDC)
- **Datadog** (Observabilidade)

---

## 📂 Estrutura do Repositório

```
.
├── app/                          # Código da aplicação
│   ├── Dockerfile
│   └── openapi.yaml              # Contrato da API (Swagger)
├── deploy/
│   ├── appspec.yaml              # AppSpec do CodeDeploy (ECS)
│   └── appspec.rendered.yaml     # Gerado no pipeline
├── infra/
│   └── terraform/
│       ├── modules/
│       │   ├── network
│       │   ├── security
│       │   ├── alb
│       │   ├── ecs
│       │   ├── rds
│       │   ├── sqs
│       │   ├── vpc_endpoints
│       │   ├── codedeploy_ecs
│       │   ├── apigateway        # API Gateway (HTTP API)
│       │   └── domain            # Route53 + ACM (Opcional)
│       └── envs/dev
└── .github/workflows/cd.yml
```

---

## 🐶 Datadog Agent (Ambiente Dev)

Como o ambiente de desenvolvimento utiliza subnets privadas sem NAT Gateway (para economia de custos), as tarefas ECS não conseguem baixar a imagem do Datadog Agent diretamente do Docker Hub ou ECR Public.

Para resolver isso, utilizamos um repositório ECR privado (`datadog-agent`) como mirror.

### Como atualizar/enviar a imagem do Datadog

Sempre que criar o ambiente do zero ou quiser atualizar a versão do agente, execute o script auxiliar:

```bash
chmod +x push_datadog_image.sh
./push_datadog_image.sh
```

Este script irá:
1. Autenticar no ECR Public.
2. Baixar a imagem oficial do Datadog.
3. Autenticar no seu ECR Privado.
4. Enviar a imagem para o seu repositório privado.

---

## 🔐 Segurança e Boas Práticas

- OIDC GitHub → AWS (sem access keys)
- Secrets no AWS Secrets Manager
- Subnets privadas
- Security Groups restritivos
- ECS Task Role ≠ ECS Execution Role
- VPC Endpoints (PrivateLink) no lugar de NAT Gateway

---

## 🚀 Pipeline de Deploy (GitHub Actions)

Fluxo do workflow (`.github/workflows/cd.yml`):

1. Checkout do código
2. Assume role AWS via OIDC
3. Login no ECR
4. Build da imagem Docker (ARM64)
5. Push da imagem para o ECR
6. Busca da última Task Definition
7. Registro de nova revisão com a nova imagem
8. Geração do AppSpec com a nova Task Definition
9. Criação do deployment no CodeDeploy
10. Espera até o deploy finalizar

---

## 🧪 Testando a Aplicação

### Descobrir o DNS do ALB
```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[].DNSName' --output text
```

### Request simples
```bash
curl http://<ALB_DNS>
```

### Healthcheck (Spring Boot)
```bash
curl http://<ALB_DNS>/actuator/health
```

---

## 📜 Comandos Importantes (AWS CLI)

### ECS
```bash
aws ecs list-services --cluster app-automatic-pipeline-dev-cluster
aws ecs list-tasks --cluster app-automatic-pipeline-dev-cluster --service-name app-automatic-pipeline-dev-api-svc
aws ecs execute-command --cluster app-automatic-pipeline-dev-cluster --task <TASK_ARN> --container api --interactive --command "/bin/sh"
```

### Logs (CloudWatch)
```bash
aws logs tail "/ecs/app-automatic-pipeline-dev-api" --follow
```

### CodeDeploy
```bash
aws deploy get-deployment --deployment-id <DEPLOYMENT_ID>
aws deploy wait deployment-successful --deployment-id <DEPLOYMENT_ID>
```

### Secrets Manager
```bash
aws secretsmanager get-secret-value --secret-id app-automatic-pipeline-dev/rds/postgres
```

---

## 🌱 Infra as Code (Terraform)

### Inicializar
```bash
terraform init
```

### Validar
```bash
terraform validate
```

### Planejar
```bash
terraform plan
```

### Aplicar
```bash
terraform apply
```

### Destruir tudo
```bash
terraform destroy
```

---

## ⚠️ Comportamentos Importantes

### ECS com CodeDeploy
Quando o ECS Service usa:
```hcl
deployment_controller { type = "CODE_DEPLOY" }
```

O Terraform **não pode atualizar `task_definition`** diretamente.

Por isso usamos:
```hcl
lifecycle {
  ignore_changes = [task_definition, desired_count]
}
```

---

### Execution Role vs Task Role

| Role | Responsabilidade |
|---|---|
| ECS Execution Role | Pull da imagem, logs, **injeção de secrets** |
| ECS Task Role | Permissões da aplicação (S3, SQS, etc.) |

---

## 💸 Otimizações de Custo

- Fargate Spot
- ARM64 (Graviton)
- Sem NAT Gateway
- VPC Endpoints
- Logs com retenção curta
- RDS em tamanho mínimo

---

## 🧨 Comandos de Deleção Forçada (Cleanup)

### Forçar deleção do ECR (imagens inclusas)
```bash
aws ecr delete-repository --repository-name app-automatic-pipeline-api --force
```

### Esvaziar S3 (com versioning)
```bash
aws s3 rm s3://app-automatic-pipeline-files --recursive
```

### Forçar deleção de Secret no Secrets Manager
```bash
aws secretsmanager delete-secret --secret-id app-automatic-pipeline-dev/rds/postgres --force-delete-without-recovery
```

⚠️ **Atenção:** esse comando remove o secret imediatamente e **sem possibilidade de recuperação**.

---

## 📌 Próximos Passos

- HTTPS com ACM
- Auto Scaling no ECS
- Observabilidade (metrics/traces)
- WAF
- Ambiente `staging`

---

## 👤 Autor

Projeto criado como **referência prática de arquitetura AWS moderna**, focado em **baixo custo**, **segurança** e **automação completa de deploy**.
