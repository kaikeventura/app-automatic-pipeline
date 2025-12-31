#!/bin/bash

# Script para fazer mirror da imagem do Datadog Agent para o ECR Privado
# Necessário porque as subnets privadas não têm acesso à internet (sem NAT Gateway)

set -e

AWS_PROFILE=app-automatic-pipeline-dev
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
REPO_NAME="datadog-agent"
IMAGE_TAG="latest"

echo "=== Iniciando processo de mirror da imagem do Datadog Agent ==="
echo "Conta AWS: ${ACCOUNT_ID}"
echo "Região: ${REGION}"
echo "ECR Destino: ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}"
echo ""

# 1. Login no ECR Public
echo "1. Fazendo login no ECR Public..."
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# 2. Pull da imagem original
echo "2. Baixando imagem public.ecr.aws/datadog/agent:${IMAGE_TAG}..."
docker pull public.ecr.aws/datadog/agent:${IMAGE_TAG}

# 3. Login no ECR Privado
echo "3. Fazendo login no ECR Privado (${ECR_URL})..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}

# 4. Taggear a imagem
echo "4. Taggeando imagem para o ECR Privado..."
docker tag public.ecr.aws/datadog/agent:${IMAGE_TAG} ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}

# 5. Push para o ECR Privado
echo "5. Enviando imagem para o ECR Privado..."
docker push ${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}

echo ""
echo "=== Sucesso! Imagem do Datadog enviada para o ECR Privado. ==="
