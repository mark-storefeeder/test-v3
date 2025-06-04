# Alias the input parameters to more descriptive names
branch_to_rebase=$1
base_branch=$2
verbose_output=${3:-false}

# Function to conditionally suppress output
run_command() {
  if [ "$verbose_output" = "true" ]; then
    "$@"
  else
    "$@" &> /dev/null
  fi
}

#run_command git checkout $branch_to_rebase
run_command git submodule update --init --recursive

handle_conflicts() {
  # Check whether there are any submodule conflicts
  if git diff --name-only | grep -q "modules/test-components"; then
    git add modules/test-components # Resolve the submodule conflict using the version in the branch that's being rebased - it'll get updated to the correct version later anyway

    if ! run_command git -c advice.mergeConflict=false -c core.editor=true rebase --continue; then
      handle_conflicts # Recursively call handle_conflicts to handle multiple conflicts
    fi
  else
    echo "ERROR: $branch_to_rebase could not be rebased onto $base_branch because of non-submodule conflicts (or an unhandled error)."
    run_command git rebase --abort
    exit 1
  fi
}

# TEMP
#cleanup() {
#  run_command git checkout main
#  run_command git submodule update --init --recursive
#}
#trap cleanup EXIT
# TEMP END

if run_command git -c advice.mergeConflict=false -c advice.submoduleMergeConflict=false rebase origin/$base_branch; then
  # git push origin $branch_to_rebase --force-with-lease
  echo "SUCCESS: $branch_to_rebase was rebased onto $base_branch."
else
  handle_conflicts
  # git push origin $branch_to_rebase --force-with-lease
  echo "SUCCESS: $branch_to_rebase was rebased onto $base_branch with submodule conflict resolution."
fi
