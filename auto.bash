# ====== set variables ======
$AWS_REGION = "us-east-1"          # <- change to your region
$REPO_NAME  = "doc"          # <- choose your repo name
$IMAGE_TAG  = "v1"                 # <- e.g., v1, latest, or a git SHA

$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$REGISTRY   = "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# ====== create ECR repo if it doesn't exist ======
try {
  aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION | Out-Null
} catch {
  aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION | Out-Null
}

# ====== login Docker to ECR ======
aws ecr get-login-password --region $AWS_REGION `
| docker login --username AWS --password-stdin $REGISTRY

# ====== build, tag, push ======
docker build -f dockerfile3 -t "${REPO_NAME}:${IMAGE_TAG}" .
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"
docker push "${REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"

# ====== verify in ECR ======
aws ecr describe-images `
  --repository-name $REPO_NAME `
  --region $AWS_REGION `
  --query "imageDetails[?contains(imageTags, '$IMAGE_TAG')].imageTags"
