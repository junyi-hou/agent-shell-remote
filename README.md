# agent-shell-tramp

Running `agent-shell` on remote machines using Emacs TRAMP.

## WIP: still testing

I am having minor issues with this pacakge:
- for some reasons, it still uses the local claude-agent-acp, instead of the remote-one

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
2.  Resolve and handle file paths between the local Emacs and the remote environment.
3.  Configure TRAMP and SSH options (like `ControlMaster`) for stable communication.

## License

GPL-3.0
