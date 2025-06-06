# Alias the input parameters to more descriptive names
repository=$1
branch=$2

# Check whether the branch exists
if gh api repos/$repository/branches/$branch --silent; then
    main_sha=$(gh api repos/$repository/branches/main --jq .commit.sha)
    branch_sha=$(gh api repos/$repository/branches/$branch --jq .commit.sha)
    behind_by=$(gh api repos/$repository/compare/$main_sha...$branch_sha --jq .behind_by)
    
    if [ "$behind_by" -gt 0 ]; then
        echo "::error::The branch $branch is $behind_by commit(s) behind main. Please update it before trying again."
        exit 1
    fi
    
    echo "::notice::The branch $branch already exists and is up to date with main."
else
    # Create the new branch locally (it will need to be pushed to remote later)
    if ! git branch $branch; then
        echo "::error::Failed to create branch $branch from main."
        exit 1
    fi
    
    echo "::notice::The branch $branch has been created locally."
fi
