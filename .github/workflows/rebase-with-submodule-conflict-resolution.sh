# Alias the input parameters to more descriptive names
branch_to_rebase=$1
base_branch=$2
submodule_path=$3

cleanup() {
  # Cleanup after ourselves in case subsequent scripts need to run
  git checkout $current_branch
  git submodule update --init --recursive
}

handle_conflicts() {
  # Check whether there are any submodule conflicts
  if git diff --name-only --diff-filter=U | grep -q "$submodule_path"; then
    git add "$submodule_path" # Resolve the submodule conflict using the version in the branch that's being rebased

    if ! git -c advice.mergeConflict=false -c core.editor=true rebase --continue; then
      handle_conflicts # Recursively call handle_conflicts to handle multiple conflicts
    fi
  else
    echo "::error::Could not rebase $branch_to_rebase onto $base_branch due to non-submodule conflicts. Please rebase manually instead."
    git rebase --abort
    exit 1
  fi
}

current_branch=$(git branch --show-current)

trap cleanup EXIT

git restore . # Because we've given execute permissions to the script, we need to revert the change before checking out another branch

if ! git checkout $branch_to_rebase; then
  echo "::error::Could not checkout $branch_to_rebase."
  exit 1
fi

if ! git submodule update --init --recursive; then
  echo "::error::Submodule update failed for $branch_to_rebase."
  exit 1
fi

if git -c advice.mergeConflict=false -c advice.submoduleMergeConflict=false rebase origin/$base_branch; then
  # git push origin $branch_to_rebase --force-with-lease
  echo "::notice::Successfully rebased $branch_to_rebase onto $base_branch."
else
  # Check if we're in a rebase state (which indicates conflicts)
  if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    handle_conflicts
    # git push origin $branch_to_rebase --force-with-lease
    echo "::notice::Successfully rebased $branch_to_rebase onto $base_branch with submodule conflict resolution."
  else
    echo "::error::Could not rebase $branch_to_rebase onto $base_branch due to an unhandled error."
    exit 1
  fi
fi
