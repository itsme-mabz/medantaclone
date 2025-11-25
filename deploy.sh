#!/bin/bash

# Quick Deployment Script for GCP Cloud Run
# Domain: drsaurav.blizon.tech

set -e

echo "🚀 Django App Deployment to GCP Cloud Run"
echo "=========================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first:"
    echo "   brew install --cask google-cloud-sdk"
    exit 1
fi

# Variables
PROJECT_ID="${GCP_PROJECT_ID:-your-project-id}"
SERVICE_NAME="medantaclone"
REGION="us-central1"
DOMAIN="drsaurav.blizon.tech"

echo "📋 Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Service Name: $SERVICE_NAME"
echo "   Region: $REGION"
echo "   Domain: $DOMAIN"
echo ""

# Prompt for project ID if not set
if [ "$PROJECT_ID" == "your-project-id" ]; then
    read -p "Enter your GCP Project ID: " PROJECT_ID
fi

# Set project
echo "🔧 Setting GCP project..."
gcloud config set project $PROJECT_ID

# Generate secret key if not exists
if [ -z "$SECRET_KEY" ]; then
    SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    echo "🔑 Generated SECRET_KEY"
fi

# Build and deploy
echo ""
echo "🏗️  Building and deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars "SECRET_KEY=$SECRET_KEY" \
  --set-env-vars "DEBUG=False" \
  --set-env-vars "ALLOWED_HOSTS=$DOMAIN,.run.app"

echo ""
echo "✅ Deployment complete!"
echo ""

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format='value(status.url)')
echo "🌐 Your app is running at: $SERVICE_URL"
echo ""

# Ask about domain mapping
read -p "Do you want to map the custom domain now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔗 Mapping custom domain..."
    gcloud run domain-mappings create \
      --service $SERVICE_NAME \
      --domain $DOMAIN \
      --region $REGION || echo "⚠️  Domain mapping may already exist or needs DNS configuration"
    
    echo ""
    echo "📝 DNS Configuration Required:"
    echo "   Add the following DNS records to your domain registrar:"
    gcloud run domain-mappings describe \
      --domain $DOMAIN \
      --region $REGION 2>/dev/null || echo "   Run: gcloud run domain-mappings describe --domain $DOMAIN --region $REGION"
fi

echo ""
echo "🎉 Deployment Summary:"
echo "   ✓ App deployed to Cloud Run"
echo "   ✓ Service URL: $SERVICE_URL"
echo "   ✓ Custom domain: $DOMAIN (configure DNS)"
echo ""
echo "📚 Next Steps:"
echo "   1. Configure DNS records for $DOMAIN"
echo "   2. Run migrations: gcloud run services update $SERVICE_NAME --command='python,manage.py,migrate'"
echo "   3. Create superuser (connect to Cloud Shell)"
echo "   4. Test your site at https://$DOMAIN"
echo ""
