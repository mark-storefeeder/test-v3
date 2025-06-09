# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --branch=*)
      branch="${1#*=}"
      shift
      ;;
    --base-branch=*)
      base_branch="${1#*=}"
      shift
      ;;
    --submodule-path=*)
      submodule_path="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to rebase-with-submodule-conflict-resolution.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$branch" ]; then
  echo "::error::Missing required parameter 'branch'"
  exit 1
fi

if [ -z "$base_branch" ]; then
  echo "::error::Missing required parameter 'base-branch'"
  exit 1
fi

if [ -z "$submodule_path" ]; then
  echo "::error::Missing required parameter 'submodule-path'"
  exit 1
fi

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
    echo "::error::Could not rebase the branch $branch onto $base_branch due to non-submodule conflicts. Please rebase manually instead."
    git rebase --abort
    exit 1
  fi
}

current_branch=$(git branch --show-current)

trap cleanup EXIT

if ! git checkout $branch; then
  echo "::error::Could not checkout the branch $branch."
  exit 1
fi

if ! git submodule update --init --recursive; then
  echo "::error::Submodule update failed for the branch $branch."
  exit 1
fi

if output=$(git -c advice.mergeConflict=false -c advice.submoduleMergeConflict=false rebase $base_branch 2>&1); then
  echo "::notice::Successfully rebased $branch onto $base_branch."
else
  # Check if we're in a rebase state (which indicates conflicts)
  if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    handle_conflicts
    echo "::notice::Successfully rebased $branch onto $base_branch with submodule conflict resolution."
  else
    echo "::error::Could not rebase $branch onto $base_branch due to an unhandled error: $output"
    exit 1
  fi
fi
