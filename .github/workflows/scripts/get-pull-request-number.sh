# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --branch=*)
      branch="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to get-pull-request-number.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$branch" ]; then
  echo "::error::Missing required parameter 'branch'"
  exit 1
fi

pull_request_number=$(gh pr list --search "head:$branch" --json number --jq '.[0].number')

if [ -z "$pull_request_number" ]; then
  echo "::error::An open pull request does not exist for the branch $branch."
  exit 1
fi

echo "pull_request_number=$pull_request_number" >> $GITHUB_OUTPUT
echo "::notice::Found pull request #$pull_request_number for the branch $branch."
