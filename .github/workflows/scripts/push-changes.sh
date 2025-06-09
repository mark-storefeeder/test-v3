# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --branch=*)
      branch="${1#*=}"
      shift
      ;;
    --dry-run=*)
      dry_run="${1#*=}"
      shift
      ;;
    --force-push=*)
      force_push="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to push-changes.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$branch" ]; then
  echo "::error::Missing required parameter 'branch'"
  exit 1
fi

push_command="git push origin $branch"

if [ "$dry_run" = "true" ]; then
  push_command="$push_command --dry-run"
fi

if [ "$force_push" = "true" ]; then
  push_command="$push_command --force-with-lease"
fi

if $push_command; then
  echo "::notice::Changes to $branch branch have been pushed."
else
  echo "::error::Failed to push changes to $branch branch."
  exit 1
fi
