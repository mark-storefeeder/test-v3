# Alias the input parameters to more descriptive names
repository=$1
branch=$2

if ! output=$(gh api repos/$repository/branches/$branch --jq .name 2>&1); then
  if echo "$output" | grep -q "Branch not found"; then
    echo "::error::The branch $branch does not exist in the repository $repository."
    exit 2 # Special exit code for branch not found
  else
    echo "::error::Could not verify whether the branch $branch exists in the repository $repository: $output"
    exit 1 # Unknown error
  fi
fi
