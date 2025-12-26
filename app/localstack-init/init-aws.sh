#!/bin/bash
awslocal s3 mb s3://ticket-images-bucket
awslocal sqs create-queue --queue-name payment-processing-queue
awslocal sqs create-queue --queue-name payment-result-queue
awslocal secretsmanager create-secret --name /secret/ticket-app-db --secret-string '{"username":"postgres","password":"postgres"}'
