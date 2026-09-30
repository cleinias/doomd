;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)
;; Specify both a dark and light theme, like so and Doom will choose which one
;; to load based on your system light/dark setting:
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (DARK . LIGHT)
;;
;; If you want more pro-active theme switching based on OS light/dark mode, look
;; up the `auto-dark' package.

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Tabs (centaur-tabs, via :ui tabs): VS Code-style keys.
;; Doom only binds tab keys for evil users, so non-evil needs these.
(map! "C-<prior>"   #'centaur-tabs-backward               ; Ctrl+PgUp: previous tab
      "C-<next>"    #'centaur-tabs-forward                ; Ctrl+PgDn: next tab
      "C-S-<prior>" #'centaur-tabs-move-current-tab-to-left
      "C-S-<next>"  #'centaur-tabs-move-current-tab-to-right)

;; Claude Code IDE: Claude in a side window on the right, like VS Code.
(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :init
  (setq claude-code-ide-terminal-backend 'ghostel  ; smoothest backend, per its README
        claude-code-ide-window-side 'right
        claude-code-ide-window-width 70)
  :config
  (claude-code-ide-emacs-tools-setup))  ; lets Claude use xref, project, etc.

;; Outline sidebar under the Treemacs file tree (VS Code's Outline view);
;; toggle with C-c o i.
(use-package! imenu-list
  :defer t
  :init
  (setq imenu-list-focus-after-activation nil
        imenu-list-auto-resize nil)
  (map! :leader :desc "Outline sidebar" "o i" #'imenu-list-smart-toggle)
  :config
  ;; imenu-list normally splits the whole frame into a new column.  Show it
  ;; instead as a left side window in the slot below Treemacs (slot -1), so the
  ;; two stack vertically like VS Code's Explorer and Outline.
  (defun +sf/imenu-list-side-window (buffer _alist)
    (display-buffer-in-side-window
     buffer '((side . left) (slot . 1) (window-height . 0.4)
              (dedicated . t) (preserve-size . (t . nil)))))
  (advice-add #'imenu-list-display-buffer :override #'+sf/imenu-list-side-window))

;; Start maximized: five panes need the whole screen.
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Left and right side windows (file tree, outline, Claude) take the full
;; frame height, so the bottom terminal popup spans only the editor area.
(setq window-sides-vertical t)

;; Doom's popups always span the whole frame width, ignoring the setting above,
;; so show the ghostel terminal (C-c o t) as a plain bottom side window instead:
;; it then sits under the editor only, like VS Code's terminal panel.
(defadvice! +sf/ghostel-under-editor-a (fn &rest args)
  :around #'+ghostel/toggle
  (let ((display-buffer-overriding-action
         '((display-buffer-in-side-window)
           (side . bottom) (slot . 0) (window-height . 0.3)
           (preserve-size . (nil . t)))))
    (apply fn args)))

;; One command for the whole VS Code-like layout: file tree + outline on the
;; left, terminal under the editor, Claude on the right.  C-c o l.
(defun +sf/ide-layout ()
  "Open file tree, outline, terminal and Claude around the current buffer."
  (interactive)
  (require 'treemacs)  ; on a fresh start it isn't loaded yet
  (let ((editor (selected-window)))
    (unless (treemacs-get-local-window) (+treemacs/toggle))
    (select-window editor)
    (imenu-list-minor-mode 1)
    (select-window editor)
    (unless (seq-some (lambda (w) (string-match-p "ghostel"
                                                  (buffer-name (window-buffer w))))
                      (window-list))
      (+ghostel/toggle))
    (select-window editor)
    (claude-code-ide)))
(map! :leader :desc "IDE layout" "o l" #'+sf/ide-layout)

;; Make it the default: the first time a project file (or the project folder,
;; in dired) is opened in this session, set up the layout once.  One session =
;; one project (`doom [run] [dir]' in ~/.bashrc, no daemon, no workspaces), so panes
;; you close yourself stay closed; C-c o l brings them back.
(defvar +sf-ide-layout-done nil)
(defun +sf/ide-layout-maybe-h ()
  (when (and (not +sf-ide-layout-done)
             (or buffer-file-name (derived-mode-p 'dired-mode))
             (doom-project-p))
    (setq +sf-ide-layout-done t)
    (run-at-time 0 nil #'+sf/project-startup)))
(add-hook 'find-file-hook #'+sf/ide-layout-maybe-h)
(add-hook 'dired-mode-hook #'+sf/ide-layout-maybe-h)

;; Per-project sessions: the open files of each project are saved when Emacs
;; exits and reopened by the next `doom run' there.  Only the buffer list is
;; kept (no frames or windows), so the layout above is always rebuilt fresh.
;; Each project gets its own desktop file under Doom's cache.
(setq desktop-restore-frames nil
      desktop-load-locked-desktop 'check-pid  ; ignore locks left by a crash
      desktop-save t)                          ; save without asking
(defvar +sf-desktop-dir nil
  "Where this session's project desktop lives, once a project is opened.")

(defun +sf/project-startup ()
  "Restore the project's saved files, then build the IDE layout."
  (require 'desktop)
  (let* ((root (doom-project-root))
         (launched (current-buffer))
         (dir (file-name-concat doom-cache-dir "desktop"
                                (replace-regexp-in-string
                                 "/" "!" (directory-file-name root)))))
    (make-directory dir t)
    (setq +sf-desktop-dir dir)
    (desktop-read dir)
    ;; Launched on a folder (`doom run'): the editor shows the most recent
    ;; restored file, or else an empty buffer, instead of a dired listing;
    ;; files are opened from the tree.
    (when (buffer-live-p launched)
      (with-current-buffer launched
        (when (derived-mode-p 'dired-mode)
          (switch-to-buffer
           (or (seq-find (lambda (b)
                           (and (buffer-file-name b)
                                (file-in-directory-p (buffer-file-name b) root)))
                         (buffer-list))
               (with-current-buffer (get-buffer-create "*scratch*")
                 (setq default-directory root)
                 (current-buffer))))
          (kill-buffer launched)))))
  (+sf/ide-layout))

(add-hook 'kill-emacs-hook
          (defun +sf/save-project-desktop-h ()
            (when +sf-desktop-dir
              (desktop-save +sf-desktop-dir t))))

;; Switching projects = a new window with its own session, like `doom run DIR'
;; in a terminal: pick from the projects opened before.  C-c o w.
(defun +sf/open-project-window (dir)
  "Open project DIR in a new, independent Doom Emacs window."
  (interactive
   (list (completing-read "Open project in new window: "
                          (projectile-relevant-known-projects) nil t)))
  (let ((default-directory (file-name-as-directory (expand-file-name dir))))
    ;; setsid + no wait: the new Emacs outlives this one.
    (call-process "setsid" nil 0 nil
                  (expand-file-name invocation-name invocation-directory)
                  "--init-directory" doom-emacs-dir default-directory)))
(map! :leader :desc "Project in new window" "o w" #'+sf/open-project-window)

;; The file tree always shows the project of the current buffer, and only that:
;; no saved project list to manage.
(after! treemacs
  (treemacs-project-follow-mode +1))

;; Python debugging with dape: a Debug Adapter Protocol client driving debugpy,
;; the same debug adapter VS Code uses.  debugpy must be installed for the
;; system python3 only; projects and their venvs need nothing (see :config).
;;
;; PyCharm's debugger keys.  As in PyCharm, clicking the gutter sets
;; breakpoints -- except that Emacs cannot make the line numbers themselves
;; clickable, so the dot and the click land in the fringe, the thin strip at
;; the window's left edge, left of the numbers (the same strip where the git
;; gutter draws its bars).  `dape-breakpoint-mode' binds the fringe clicks to
;; act on the clicked line: left-click toggles a breakpoint, middle-click
;; asks for a condition, right-click asks for a log message.
(use-package! dape
  :defer t
  :hook (python-base-mode . dape-breakpoint-mode)
  :init
  (map! "S-<f9>"  #'dape                      ; Debug: start a session
        "<f9>"    #'dape-continue             ; Resume
        "<f8>"    #'dape-next                 ; Step Over
        "<f7>"    #'dape-step-in              ; Step Into
        "S-<f8>"  #'dape-step-out             ; Step Out
        "C-<f8>"  #'dape-breakpoint-toggle    ; Toggle Breakpoint
        "C-<f2>"  #'dape-quit)                ; Stop
  :config
  ;; dape's stock debugpy config runs the adapter and the debugged program with
  ;; the same interpreter (debugpy's :python defaults to the adapter's own
  ;; sys.executable), so the project's venv would need its own debugpy.  Split
  ;; the two instead: the adapter runs on the system python, which has debugpy,
  ;; and launches the program with the project's interpreter.  debugpy hands its
  ;; launcher to that interpreter as a file path rather than importing it, so a
  ;; project needs nothing installed.  dape calls a function given as a config
  ;; value, the same way it uses `dape-cwd'.
  (defun +sf/python-executable ()
    "Interpreter to debug with: the active virtualenv or conda environment,
else a .venv/ or venv/ in the project root, else plain \"python\"."
    (let ((root (or (doom-project-root) default-directory)))
      (or (seq-find
           #'file-executable-p
           (mapcar (lambda (dir) (expand-file-name "bin/python" dir))
                   (delq nil (list (getenv "VIRTUAL_ENV")   ; pyvenv, direnv, activated shell
                                   (getenv "CONDA_PREFIX")
                                   (expand-file-name ".venv" root)
                                   (expand-file-name "venv" root)))))
          "python")))
  ;; Before opening its port, debugpy's adapter reads the metadata of every
  ;; package installed for its python (~600 on the system python) just to log
  ;; them, logging on or not.  On a cold disk cache that takes ~5 s, longer
  ;; than the ~3 s dape waits for the port, and the session dies with "Unable
  ;; to connect to dap server".  So read the same files first, in the config's
  ;; `ensure' step, which dape runs to completion before starting the adapter;
  ;; the adapter then finds them cached.  The defvar keeps dape's own `ensure'
  ;; (shared by both debugpy configs) across config reloads.
  (defvar +sf/debugpy-stock-ensure
    (plist-get (alist-get 'debugpy dape-configs) 'ensure))
  (defun +sf/debugpy-ensure (config)
    "Run dape's debugpy checks, then warm the cache of package metadata."
    (funcall +sf/debugpy-stock-ensure config)
    (process-file (dape-config-get config 'command) nil nil nil "-c"
                  "import importlib.metadata as m; [d.version for d in m.distributions()]"))
  (dolist (key '(debugpy debugpy-module))
    (plist-put (alist-get key dape-configs) 'command "python3")
    (plist-put (alist-get key dape-configs) :python #'+sf/python-executable)
    (plist-put (alist-get key dape-configs) 'ensure #'+sf/debugpy-ensure)))

;; Doom's popup catch-all ("^\\*") would otherwise turn these buffers into
;; bottom popups; let the packages manage their own side windows instead.
(set-popup-rule! "^\\*claude-code\\[" :ignore t)
(set-popup-rule! "^\\*Ilist\\*" :ignore t)
