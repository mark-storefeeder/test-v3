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
      echo "::error::Unknown parameter supplied to create-and-verify-branch.sh: $1"
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

# Check whether the branch exists
if gh api repos/$repository/branches/$branch --silent; then
    main_sha=$(gh api repos/$repository/branches/main --jq .commit.sha)
    branch_sha=$(gh api repos/$repository/branches/$branch --jq .commit.sha)
    behind_by=$(gh api repos/$repository/compare/$main_sha...$branch_sha --jq .behind_by)
    
    if [ "$behind_by" -gt 0 ]; then
        echo "::error::The branch $branch is $behind_by commit(s) behind main. Please update it before trying again."
        exit 1
    fi

    if ! git fetch origin $branch:$branch; then
        echo "::error::Failed to fetch the branch $branch from origin."
        exit 1
    fi

    echo "::notice::The branch $branch already exists and is up to date with main."
else
    # Create the new branch locally (it will need to be pushed to remote later)
    if ! git branch $branch; then
        echo "::error::Failed to create the branch $branch."
        exit 1
    fi
    
    echo "::notice::The branch $branch has been created locally."
fi
