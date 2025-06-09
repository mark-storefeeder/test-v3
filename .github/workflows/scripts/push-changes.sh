# Alias the input parameters to more descriptive names
branch=$1
dry_run=$2
force_push=$3

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
