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

# Rebase all submodules against their upstream repositories
rebase-all:
    for dir in $(git submodule --quiet foreach --recursive 'echo $path'); do \
      echo "Rebasing $dir..."; \
      cd "$dir" || exit 1; \
      git fetch upstream; \
      if git show-ref --verify --quiet refs/remotes/upstream/main; then \
        git rebase upstream/main || { echo "Rebase failed in $dir"; exit 1; }; \
      elif git show-ref --verify --quiet refs/remotes/upstream/master; then \
        git rebase upstream/master || { echo "Rebase failed in $dir"; exit 1; }; \
      else \
        echo "Neither upstream/main nor upstream/master found in $dir"; \
        exit 1; \
      fi; \
      cd - > /dev/null || exit 1; \
    done
