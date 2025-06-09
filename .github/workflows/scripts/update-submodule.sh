# Parse named parameters
while [[ $# -gt 0 ]]; do
  case $1 in
    --local-branch=*)
      local_branch="${1#*=}"
      shift
      ;;
    --submodule-repository=*)
      submodule_repository="${1#*=}"
      shift
      ;;
    --submodule-branch=*)
      submodule_branch="${1#*=}"
      shift
      ;;
    --submodule-path=*)
      submodule_path="${1#*=}"
      shift
      ;;
    --squash-commit=*)
      squash_commit="${1#*=}"
      shift
      ;;
    *)
      echo "::error::Unknown parameter supplied to update-submodule.sh: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$local_branch" ]; then
  echo "::error::Missing required parameter 'local-branch'"
  exit 1
fi

if [ -z "$submodule_repository" ]; then
  echo "::error::Missing required parameter 'submodule-repository'"
  exit 1
fi

if [ -z "$submodule_branch" ]; then
  echo "::error::Missing required parameter 'submodule-branch'"
  exit 1
fi

if [ -z "$submodule_path" ]; then
  echo "::error::Missing required parameter 'submodule-path'"
  exit 1
fi

if [ -z "$squash_commit" ]; then
  echo "::error::Missing required parameter 'squash-commit'"
  exit 1
fi

cleanup() {
  # Cleanup after ourselves in case subsequent scripts need to run
  git checkout $current_branch
  git submodule update --init --recursive
}

current_branch=$(git branch --show-current)

trap cleanup EXIT

# Check whether the target branch exists in the submodule repository
if ! .github/workflows/scripts/verify-branch-exists.sh --repository="$submodule_repository" --branch="$submodule_branch"; then
  exit_code=$?
  if [ $exit_code -eq 2 ]; then
    echo "::notice::The branch $submodule_branch does not exist in the submodule repository; skipping submodule update."
  else
    exit 1
  fi
fi

original_path=$(pwd)

if ! git checkout $local_branch; then
  echo "::error::Could not checkout the branch $local_branch."
  exit 1
fi

if ! git submodule update --init --recursive; then
  echo "::error::Submodule update failed for the branch $local_branch."
  exit 1
fi

cd $submodule_path

if ! git fetch origin $submodule_branch; then
  echo "::error::Could not fetch origin/$submodule_branch."
  exit 1
fi

if ! git checkout $submodule_branch; then
  echo "::error::Could not checkout $submodule_branch."
  exit 1
fi

cd $original_path

# Update the submodule to reference the head of the target branch in the submodule repository
if ! git add $submodule_path; then
  echo "::error::Could not add $submodule_path."
  exit 1
fi

if git diff --staged --quiet; then
  echo "::notice::$submodule_path is already up to date with the branch $submodule_branch in the submodule repository."
else
  submodule_commit=$(git submodule status $submodule_path | cut -d' ' -f2 | cut -c1-7)

  if [ "$squash_commit" = "true" ]; then
    git commit --amend --no-edit --allow-empty
    echo "::notice::$submodule_path has been updated to reference the head of the branch $submodule_branch (commit $submodule_commit) in the submodule repository and the commit has been squashed into the previous commit."
  else
    git commit --message "Update $submodule_path to reference $submodule_branch branch"
    echo "::notice::$submodule_path has been updated to reference the head of the branch $submodule_branch (commit $submodule_commit) in the submodule repository."
  fi
fi
