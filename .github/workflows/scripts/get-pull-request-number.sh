# Alias the input parameters to more descriptive names
branch=$1

pr_number=$(gh pr list --search "head:$branch" --json number --jq '.[0].number')

if [ -z "$pr_number" ]; then
  echo "::error::An open pull request does not exist for the branch $branch."
  exit 1
fi

echo "pr_number=$pr_number" >> $GITHUB_OUTPUT
echo "::notice::Found pull request #$pr_number for the branch $branch."
