# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --repository=*)
      repository="${1#*=}"
      shift
      ;;
    --branch=*)
      branch="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to verify-branch-exists.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$repository" ]; then
  echo "::error::Missing required parameter 'repository'"
  exit 1
fi

if [ -z "$branch" ]; then
  echo "::error::Missing required parameter 'branch'"
  exit 1
fi

if ! output=$(gh api repos/$repository/branches/$branch --jq .name 2>&1); then
  if echo "$output" | grep -q "Branch not found"; then
    echo "::error::The branch $branch does not exist in the repository $repository."
    exit 2 # Special exit code for branch not found
  else
    echo "::error::Could not verify whether the branch $branch exists in the repository $repository: $output"
    exit 1 # Unknown error
  fi
fi
