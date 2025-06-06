# Alias the input parameters to more descriptive names
repository=$1
branch=$2

# Check whether the branch exists
if gh api repos/$repository/branches/$branch --silent; then
    main_sha=$(gh api repos/$repository/branches/main --jq .commit.sha)
    branch_sha=$(gh api repos/$repository/branches/$branch --jq .commit.sha)

    # Check if branch is behind main
    if ! gh api repos/$repository/compare/$branch_sha...$main_sha --jq .behind_by | grep -q '^0$'; then
        echo "::error::The branch $branch is behind main. Please update it before trying again."
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
