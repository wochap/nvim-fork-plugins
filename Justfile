set shell := ["bash", "-euxo", "pipefail", "-c"]

_update_submodule_remote repository_name remote_user:
    cd {{ repository_name }}; \
    git remote remove upstream || true; \
    git remote add upstream https://github.com/{{ remote_user }}/{{ repository_name }}.git; \
    cd ../

init:
    git submodule update --init --recursive

    just _update_submodule_remote nvim-window-picker s1n7ax
    just _update_submodule_remote img-clip.nvim HakonHarnes
    just _update_submodule_remote nvim-treesitter-context nvim-treesitter
    just _update_submodule_remote git-conflict.nvim akinsho
    just _update_submodule_remote lsp-lens.nvim VidocqH
    just _update_submodule_remote bufferline.nvim akinsho
    just _update_submodule_remote noice.nvim folke
    just _update_submodule_remote nvim-highlight-colors brenoprata10

# Rebase a specific submodule against its upstream repository
rebase repository_name:
    #!/usr/bin/env bash

    dir={{ repository_name }}
    echo
    echo "Rebasing $dir..."
    cd "$dir" || exit 1
    git fetch upstream
    if git show-ref --verify --quiet refs/remotes/upstream/main; then
        git rebase upstream/main || { echo "{{{{ style('error') }}}}Rebase failed in $dir{{ NORMAL }}"; exit 1; }
    elif git show-ref --verify --quiet refs/remotes/upstream/master; then
        git rebase upstream/master || { echo "{{{{ style('error') }}}}Rebase failed in $dir{{ NORMAL }}"; exit 1; }
    else
        echo "{{ style('error') }}Neither upstream/main nor upstream/master found in $dir{{ NORMAL }}"
        exit 1
    fi
    cd - > /dev/null || exit 1
    echo "{{ style('command') }}{{ GREEN }}Successfully rebased $dir{{ NORMAL }}"

# Rebase all submodules against their upstream repositories
rebase-all:
    #!/usr/bin/env bash

    for dir in $(git submodule --quiet foreach --recursive 'echo $path'); do
      echo;
      echo "Rebasing $dir...";
      cd "$dir" || exit 1;
      git fetch upstream;
      if git show-ref --verify --quiet refs/remotes/upstream/main; then
        git rebase upstream/main || { echo "{{{{ style('error') }}}}Rebase failed in $dir{{ NORMAL }}"; exit 1; };
      elif git show-ref --verify --quiet refs/remotes/upstream/master; then
        git rebase upstream/master || { echo "{{{{ style('error') }}}}Rebase failed in $dir{{ NORMAL }}"; exit 1; };
      else
        echo "{{ style('error') }}Neither upstream/main nor upstream/master found in $dir{{ NORMAL }}";
        exit 1;
      fi;
      cd - > /dev/null || exit 1;
    done

check-upstream:
    set +x; \
    for dir in $(git submodule --quiet foreach --recursive 'echo $path'); do \
      printf "\n"; \
      echo "Checking $dir..."; \
      cd "$dir" || exit 1; \
      git fetch upstream --quiet; \
      UPSTREAM_BRANCH=""; \
      if git show-ref --verify --quiet refs/remotes/upstream/main; then \
        UPSTREAM_BRANCH="upstream/main"; \
      elif git show-ref --verify --quiet refs/remotes/upstream/master; then \
        UPSTREAM_BRANCH="upstream/master"; \
      fi; \
      if [ -n "$UPSTREAM_BRANCH" ]; then \
        NEW_COMMITS=$(git rev-list HEAD.."$UPSTREAM_BRANCH"); \
        if [ -n "$NEW_COMMITS" ]; then \
          COUNT=$(echo "$NEW_COMMITS" | wc -l | xargs); \
          echo "{{ style('warning') }}Submodule $dir has $COUNT new commits in $UPSTREAM_BRANCH{{ NORMAL }}"; \
          git --no-pager log --pretty=format:"  %C(yellow)%h%C(reset) %s %C(green)(%cr)%C(reset) %C(bold blue)<%an>%C(reset)" HEAD.."$UPSTREAM_BRANCH"; \
          printf "\n"; \
        else \
          echo "{{ style('command') }}{{ GREEN }}Submodule $dir is up to date{{ NORMAL }}"; \
        fi; \
      else \
        echo "{{ style('error') }}No upstream branch found for $dir{{ NORMAL }}"; \
      fi; \
      cd - > /dev/null || exit 1; \
    done
