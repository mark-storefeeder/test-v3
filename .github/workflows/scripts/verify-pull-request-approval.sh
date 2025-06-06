# Alias the input parameters to more descriptive names
pr_number=$1
team_name=$2

# Get the list of reviewers who have approved this pull request
if ! approvals=$(gh pr view $pr_number --json reviews --jq '.reviews[] | select(.state == "APPROVED") | .author.login'); then
  echo "::error::Failed to get the list of reviewers who have approved the pull request #$pr_number"
  exit 1
fi

if [ -z "$approvals" ]; then
  echo "::error::Pull request #$pr_number requires at least one approval."
  exit 1
fi

# Get the list of team members
if ! team_members=$(gh api orgs/StoreFeeder/teams/$team_name/members --jq '.[].login'); then
  echo "::error::Failed to get the list of team members for team $team_name"
  exit 1
fi

echo "Team members: $(echo "$team_members" | sed ':a;N;$!ba;s/\n/, /g')"
has_approval=false

# Check if any team member has approved this pull request
while IFS= read -r approver; do
  if echo "$team_members" | grep -q "^$approver$"; then
    has_approval=true
    break
  fi
done <<< "$approvals"

if [ "$has_approval" = false ]; then
  echo "::error::Pull request #$pr_number requires at least one approval from a member of $team_name."
  exit 1
fi

echo "::notice::Pull request #$pr_number has been approved by a member of $team_name."
