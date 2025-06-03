          git checkout $1
          git submodule update --init --recursive
          
          # Rebase onto the base branch
          if git -c advice.mergeConflict=false -c advice.submoduleMergeConflict=false rebase origin/$2; then
            # git push origin $1 --force-with-lease
            echo "Successfully rebased $1 onto $2"
          else
            # If rebase failed, check if it's due to submodule conflicts
            if git diff --name-only | grep -q "modules/test-components"; then
              echo "Detected submodule conflicts in modules/test-components"

              # Resolve the submodule conflict using the version in the branch that's being rebased - it'll get updated to the correct version later anyway.
              git add modules/test-components
              git -c core.editor=true rebase --continue

              # git push origin $1 --force-with-lease
              echo "Successfully rebased $1 onto $2 with submodule conflict resolution"
            else
              echo "Rebase failed with non-submodule conflicts. Please resolve conflicts manually."
              exit 1
            fi
          fi
