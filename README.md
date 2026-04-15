# agent-shell-tramp

Running `agent-shell` on remote machines using Emacs TRAMP.

## Description

`agent-shell-tramp` is an Emacs package that extends `agent-shell` with TRAMP support. It allows you to run shell processes and manage files on remote hosts via TRAMP seamlessly, just as you would locally.

## Installation

### Manual

Clone this repository and add the path to your Emacs `load-path`:

```elisp
(add-to-list 'load-path "/path/to/agent-shell-tramp")
(require 'agent-shell-tramp)
```

### With `use-package`

```elisp
(use-package agent-shell-tramp
  ;; or :ensure if using elpaca with use-package integration
  :straight (:host github :repo "junyi-hou/agent-shell-remote")
  :config
  (agent-shell-tramp-mode 1))
```

## Usage

Enable the minor mode globally:

```elisp
(agent-shell-tramp-mode 1)
```

Once enabled, `agent-shell` will automatically detect when you are in a remote directory (via TRAMP) and:

1.  Start the necessary client processes on the remote machine.
2.  Resolve and handle file paths between local Emacs and the remote environment.

## Approaches

The bulk of this work is based on an idea by [csheaff](https://github.com/csheaff) from this [PR](https://github.com/xenodium/agent-shell/pull/205). There are two ways to start the agent (with the configured environment variables) on a remote host:
1. By using `:file-handler t` in `make-process` and replacing `(executable-find COMMAND)` with `(executable-find COMMAND t)`. This approach finds the agent executable and applies environment variables in a TRAMP-native way (i.e., using `tramp-remote-path` and `tramp-remote-process-environment`).
2. By (ab)using the `agent-shell-container-command-runner` to prepend `ssh user@remote -- bash -lc` to the agent shell commands to launch the agent directly via an SSH command. Applying environment variables is trickier in this setting, as one must either pass them to the remote host via the `SendEnv` option (which requires modifying the `sshd` config on the remote machine) or include them in the `bash -lc` command.

As discussed in the PR, option 1 is better than option 2. Despite this, the current implementation follows option 2 because it is less invasive—it does not require [modifying acp.el](https://github.com/xenodium/acp.el/pull/9), which I attempted but failed (see the `use-cl-flet` branch of this repo). For some reason, adding arguments to `make-process` and `executable-find` in `acp.el` and `agent-shell` with `cl-flet` or `cl-letf` does not work. That said, option 1 is still a more stable implementation, and I intend to revisit it in the future. PRs and comments are more than welcome if you know how to make it work.


## License

GPL-3.0
