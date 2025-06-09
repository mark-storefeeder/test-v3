# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --pull-request-number=*)
      pull_request_number="${1#*=}"
      shift
      ;;
    --merge-strategy=*)
      merge_strategy="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to merge-pull-request.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$pull_request_number" ]; then
  echo "::error::Missing required parameter 'pull-request-number'"
  exit 1
fi

if [ "$merge_strategy" != "squash" ] && [ "$merge_strategy" != "rebase" ]; then
  if gh pr view $pull_request_number --json labels --jq '.labels[].name' | grep -q "don't squash"; then
    merge_strategy="rebase"
  else
    merge_strategy="squash"
  fi
fi

if gh pr merge $pull_request_number --$merge_strategy; then
  echo "::notice::Pull request $pull_request_number has been successfully merged (using $merge_strategy)."
else
  echo "::error::Failed to merge pull request $pull_request_number."
  exit 1
fi
