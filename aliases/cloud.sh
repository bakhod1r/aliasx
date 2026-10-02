# Cloud CLIs: read-only identity and listing only.

if has aws; then
  # == AWS
  alias awswho='aws sts get-caller-identity'  # current AWS identity
  alias awsprofiles='aws configure list-profiles'  # AWS profiles
fi
if has az; then
  # == Azure
  alias azwho='az account show'  # current Azure account
  alias azaccounts='az account list --output table'  # Azure subscriptions
fi
if has gcloud; then
  # == Google Cloud
  alias gcwho='gcloud auth list'  # gcloud accounts
  alias gcproject='gcloud config get-value project'  # current GCP project
  alias gcprojects='gcloud projects list'  # GCP projects
fi
