# Alias the input parameters to more descriptive names
repository=$1
branch=$2

if ! output=$(gh api repos/$repository/branches/$branch --jq .name 2>&1); then
  if echo "$output" | grep -q "Branch not found"; then
    echo "::error::The branch $branch does not exist in the repository $repository"
  else
    echo "::error::Could not verify whether the branch $branch exists in the repository $repository: $output"
  fi
  exit 1
fi
