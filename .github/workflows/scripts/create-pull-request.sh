# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --branch=*)
      branch="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to create-pull-request.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$branch" ]; then
  echo "::error::Missing required parameter 'branch'"
  exit 1
fi

# Check if a pull request already exists
if ! gh pr list --head $branch --base main --json number --jq 'length' | grep -q '^[1-9]'; then
  gh pr create \
    --title $branch \
    --body $branch \
    --head $branch \
    --base main \
    --label "don't squash"

  echo "::notice::A pull request for branch $branch has been created."
else
  echo "::notice::A pull request for branch $branch already exists."
fi
