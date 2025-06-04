# Alias the input parameters to more descriptive names
branch_to_rebase=$1
base_branch=$2
submodule_path=$3

current_branch=$(git branch --show-current)

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
    echo "ERROR: $branch_to_rebase could not be rebased onto $base_branch because of non-submodule conflicts. Please rebase manually instead."
    git rebase --abort
    exit 1
  fi
}

trap cleanup EXIT

git restore . # Because we've given execute permissions to the script, we need to revert the change before checking out another branch

if ! git checkout $branch_to_rebase; then
  echo "ERROR: $branch_to_rebase could not be checked out."
  exit 1
fi

if ! git submodule update --init --recursive; then
  echo "ERROR: $branch_to_rebase submodule update failed."
  exit 1
fi

if git -c advice.mergeConflict=false -c advice.submoduleMergeConflict=false rebase origin/$base_branch; then
  # git push origin $branch_to_rebase --force-with-lease
  echo "SUCCESS: $branch_to_rebase was rebased onto $base_branch."
else
  # Check if we're in a rebase state (which indicates conflicts)
  if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    handle_conflicts
    # git push origin $branch_to_rebase --force-with-lease
    echo "SUCCESS: $branch_to_rebase was rebased onto $base_branch with submodule conflict resolution."
  else
    echo "ERROR: $branch_to_rebase could not be rebased onto $base_branch due to an unhandled error."
    exit 1
  fi
fi
