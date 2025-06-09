# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --pull-request-number=*)
      pull_request_number="${1#*=}"
      shift
      ;;
    --repository-owner=*)
      team_repository_owner="${1#*=}"
      shift
      ;;
    --team-name=*)
      team_name="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to verify-pull-request-approval.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$pull_request_number" ]; then
  echo "::error::Missing required parameter 'pull-request-number'"
  exit 1
fi

if [ -z "$team_repository_owner" ]; then
  echo "::error::Missing required parameter 'repository-owner'"
  exit 1
fi

if [ -z "$team_name" ]; then
  echo "::error::Missing required parameter 'team-name'"
  exit 1
fi

# Get the list of reviewers who have approved this pull request
if ! approvals=$(gh pr view $pull_request_number --json reviews --jq '.reviews[] | select(.state == "APPROVED") | .author.login'); then
  echo "::error::Failed to get the list of reviewers who have approved the pull request #$pull_request_number"
  exit 1
fi

if [ -z "$approvals" ]; then
  echo "::error::Pull request #$pull_request_number requires at least one approval."
  exit 1
fi

# Get the list of team members
if ! team_members=$(gh api orgs/$team_repository_owner/teams/$team_name/members --jq '.[].login'); then
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
  echo "::error::Pull request #$pull_request_number requires at least one approval from a member of $team_name."
  exit 1
fi

echo "::notice::Pull request #$pull_request_number has been approved by a member of $team_name."
