;;; agent-shell-tramp.el --- running agent-shell on remote machine using tramp -*- lexical-binding: t -*-

;;; Commentary:
;;
;; This package provides TRAMP support for `agent-shell`.
;; It allows `agent-shell` to run processes on remote machines
;; using Emacs TRAMP functionality.
;;
;; To use it, enable `agent-shell-tramp-mode`. This will
;; automatically add advice to `agent-shell` and `acp` to
;; handle remote file paths and process execution.
;;
;; Usage:
;;   (require 'agent-shell-tramp)
;;   (agent-shell-tramp-mode 1)
;;
;; Then, when you are in a buffer visiting a remote file via TRAMP,
;; running `agent-shell' will work as expected on the remote host.

;;; Code:
(eval-when-compile
  (require 'cl-lib))

(require 'map)
(require 'acp)
(require 'agent-shell)

(defvar tramp-use-ssh-controlmaster-options)
(defvar tramp-ssh-controlmaster-options)

(declare-function agent-shell-cwd "agent-shell")
(declare-function tramp-tramp-file-p "tramp")
(declare-function tramp-dissect-file-name "tramp")
(declare-function tramp-file-name-localname "tramp")
(declare-function tramp-make-tramp-file-name "tramp")

(defvar agent-shell-path-resolver-function)
(defvar agent-shell-container-command-runner)

;; (defun agent-shell-tramp--advice-acp (orig-fun &rest args)
;;   "Around advice for `acp--start-client' to enable TRAMP / remote support."
;;   (let ((client (plist-get args :client)))
;;     ;; (message "running client at %s"
;;     ;;          (executable-find (map-elt client :command)
;;     ;;                           (file-remote-p default-directory)))
;;     (if (file-remote-p default-directory)
;;         (let ((tramp-use-ssh-controlmaster-options 'suppress)
;;               (tramp-ssh-controlmaster-options
;;                "-o ControlMaster=no -o ControlPath=none"))
;;           (cl-flet*
;;            ((make-process
;;              (&rest args)
;;              (let ((process nil))
;;                (let ((modified-args (copy-sequence args))
;;                      (stderr-buffer
;;                       (get-buffer-create
;;                        (format
;;                         "acp-client-stderr(%s)-%s"
;;                         (map-elt client :command) (map-elt client :instance-count)))))
;;                  (setq modified-args (plist-put modified-args :stderr stderr-buffer))
;;                  ;; Ensure :file-handler is also set if you're on Tramp
;;                  (setq modified-args (plist-put modified-args :file-handler t))
;;                  (setq process (apply #'make-process modified-args))
;;                  (accept-process-output process 0.1)
;;                  process)))
;;             (make-pipe-process (&rest args) nil)
;;             (executable-find (command &rest _) (apply #'executable-find `(,command t)))
;;             (tramp-direct-async-process-p (&rest _) nil))
;;            (apply orig-fun args)))
;;       (apply orig-fun args))))

;; (defun agent-shell-tramp--advice-agent-shell (orig-fun &rest args)
;;   "Around advice for `agent-shell--start' to enable TRAMP / remote support."
;;   (cl-flet
;;    ((executable-find (command &rest _) (apply #'executable-find `(,command t))))
;;    (apply orig-fun args)))

;; (defun agent-shell-tramp--pass-env-var (var)
;;   "VAR should be output from `agent-shell-make-environment-variables`"
;;   (mapcar
;;    (lambda (env)
;;      (if-let* ((env-list (string-split env "="))
;;                (value (cadr env-list))
;;                (_ (string-match-p " " value)))
;;        (format "export %s;" (string-join `(,(car env-list) ,(format "'%s'" value)) "="))
;;        (format "export %s;" env)))
;;    var))

(defun agent-shell-tramp--command-runner (buffer)
  "Return command prefix for running commands on TRAMP remote host.
BUFFER is the agent-shell buffer.
Returns nil for non-TRAMP buffers, allowing local execution."
  (with-current-buffer buffer
    (let
        ((cwd (agent-shell-cwd))
         ;; (env-vars
         ;;  (agent-shell-tramp--pass-env-var agent-shell-anthropic-claude-environment))
         )
      (when (tramp-tramp-file-p cwd)
        (let* ((vec (tramp-dissect-file-name cwd))
               (method (tramp-file-name-method vec))
               (user (tramp-file-name-user vec))
               (host (tramp-file-name-host vec))
               (port (tramp-file-name-port vec)))
          (unless (member method '("ssh" "scp" nil))
            (error "TRAMP method '%s' not supported; only SSH is supported" method))
          (when (tramp-file-name-hop vec)
            (error "Multi-hop TRAMP paths not supported"))
          (append
           '("ssh")
           (when port
             `("-p" ,port))
           '("-o" "SendEnv=ANTHROPIC_AUTH_TOKEN")
           `(,(if user
                  (format "%s@%s" user host)
                host))
           '("--" "bash" "-lc")))))))

(defun agent-shell-remote-resolve-tramp-path (path)
  (let* ((cwd (agent-shell-cwd))
         (tramp-vec (and (tramp-tramp-file-p cwd) (tramp-dissect-file-name cwd))))
    (cond
     ;; Path is already a TRAMP path - strip the prefix for the agent
     ((tramp-tramp-file-p path)
      (tramp-file-name-localname (tramp-dissect-file-name path)))
     ;; Path is a remote-local path - add TRAMP prefix for Emacs
     (tramp-vec
      (tramp-make-tramp-file-name tramp-vec path))
     ;; Not in a TRAMP context
     (t
      path))))

(defvar agent-shell-remote--orig-path-resolver-function nil)
(defvar agent-shell-remote--orig-container-command-runner nil)

;;;###autoload
(define-minor-mode agent-shell-tramp-mode
  "Minor mode to enable agent-shell TRAMP remote support."
  :global t
  :group
  'agent-shell
  (if agent-shell-tramp-mode
      (setq
       ;; save orig value
       agent-shell-remote--orig-path-resolver-function
       agent-shell-path-resolver-function
       agent-shell-remote--orig-container-command-runner agent-shell-container-command-runner

       ;; update values
       agent-shell-container-command-runner #'agent-shell-tramp--command-runner
       agent-shell-path-resolver-function #'agent-shell-remote-resolve-tramp-path)
    ;; restore values
    (setq
     agent-shell-path-resolver-function agent-shell-remote--orig-path-resolver-function
     agent-shell-container-command-runner agent-shell-remote--orig-path-resolver-function

     agent-shell-remote--orig-path-resolver-function nil
     agent-shell-remote--orig-path-resolver-function nil)))

(provide 'agent-shell-tramp)
;;; agent-shell-tramp.el ends here
