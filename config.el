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

;; Fonts: prose in Noto Serif, everything else in Hack, both at 12 pt (a float
;; :size is in points).  Text buffers -- Markdown, Org, LaTeX, plain text,
;; commit messages -- use `mixed-pitch-mode' (below), which shows them in the
;; variable-pitch font but keeps code, tables and line numbers monospaced.
;; Code, the file tree, the outline and the terminals, Claude's included, stay
;; in Hack: a terminal draws on a grid of equal-width cells.
(setq doom-font (font-spec :family "Hack" :size 12.0)
      doom-variable-pitch-font (font-spec :family "Noto Serif" :size 12.0))

(use-package! mixed-pitch
  :hook (text-mode . +sf/mixed-pitch-maybe-h)
  :init
  ;; BibTeX and YAML are text modes too, but they are data: keep them aligned.
  (defun +sf/mixed-pitch-maybe-h ()
    (unless (derived-mode-p 'bibtex-mode 'yaml-mode)
      (mixed-pitch-mode 1)))
  :config
  ;; LaTeX verbatim text stays monospaced, like code in Org and Markdown:
  ;; \verb, the verbatim environment, and lstlisting or minted in documents
  ;; that load listings or minted.
  (add-to-list 'mixed-pitch-fixed-pitch-faces 'font-latex-verbatim-face))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'modus-operandi-tinted)  ; built in: high-contrast light theme
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

;; Claude Code IDE: Claude in a side window on the right of the editor.  Its
;; width is set to a third of the editor frame when the layout is built.
(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :init
  (setq claude-code-ide-terminal-backend 'ghostel  ; smoothest backend, per its README
        claude-code-ide-window-side 'right
        claude-code-ide-window-width 70)
  :config
  (claude-code-ide-emacs-tools-setup))  ; lets Claude use xref, project, etc.

;; Outline sidebar (VS Code's Outline view); toggle with C-c o i.
(use-package! imenu-list
  :defer t
  :init
  (setq imenu-list-focus-after-activation nil
        imenu-list-auto-resize nil)
  (map! :leader :desc "Outline sidebar" "o i" #'imenu-list-smart-toggle)
  :config
  ;; imenu-list normally splits the whole frame into a new column.  With one
  ;; frame, show it instead as a left side window in the slot below Treemacs
  ;; (slot -1), so the two stack vertically like VS Code's Explorer and Outline.
  ;; With two frames it already sits in the panel frame: keep it there.
  (defun +sf/imenu-list-side-window (buffer _alist)
    (or (get-buffer-window buffer 'visible)
        (display-buffer-in-side-window
         buffer '((side . left) (slot . 1) (window-height . 0.4)
                  (dedicated . t) (preserve-size . (t . nil))))))
  (advice-add #'imenu-list-display-buffer :override #'+sf/imenu-list-side-window)
  ;; Highlighting the entry at point looks for the outline in the selected
  ;; frame only; look in the panel frame too.
  (defadvice! +sf/imenu-list-show-current-entry-a ()
    :override #'imenu-list--show-current-entry
    (when-let* ((window (get-buffer-window (imenu-list-get-buffer-create) 'visible)))
      (let ((line-number (cl-position (imenu-list--current-entry)
                                      imenu-list--line-entries
                                      :test 'equal)))
        (with-selected-window window
          (goto-char (point-min))
          (forward-line line-number)
          (hl-line-mode 1))))))

;; Start maximized: the panes need the whole screen.
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Left and right side windows (file tree, outline, Claude) take the full
;; frame height, so the bottom terminal popup spans only the editor area.
(setq window-sides-vertical t)

;;; Two monitors, two frames
;;
;; With a landscape and a portrait monitor (screen 0 and screen 1), the layout
;; uses one frame on each:
;;
;;   editor frame, landscape         panel frame, portrait
;;   +-------------------+-------+   +-----------+-----------+
;;   |                   |       |   | file tree |  outline  |
;;   |      editor       |Claude |   +-----------+-----------+
;;   |                   |       |   |        terminal       |
;;   +-------------------+-------+   +-----------------------+
;;
;; Everything opened from the panel frame (files from the tree, outline
;; entries, C-x C-f in the terminal) lands in the editor frame.  The panel
;; toggles (C-c o p, C-c o i, C-c o t) act on the panel frame from either
;; frame; C-c o l rebuilds both.  Closing the editor frame quits Emacs;
;; closing the panel frame just closes it.  With a single monitor, everything
;; goes in one frame as before.
;;
;; On X11 the frames are placed on their monitors here.  On Wayland Emacs can't
;; place its frames: add a KWin window rule (System Settings > Window
;; Management > Window Rules) sending the window titled "Doom panels" to the
;; portrait screen.

(defvar +sf-editor-frame nil "The frame with the editor and Claude.")
(defvar +sf-panel-frame nil "The frame with the file tree, outline and terminal.")

(defun +sf/two-frames-p ()
  (and (frame-live-p +sf-panel-frame) (frame-live-p +sf-editor-frame)))

(defun +sf/monitors ()
  "With two monitors or more, return (EDITOR-MONITOR . PANEL-MONITOR).
The editor goes on the first landscape monitor, the panels on a portrait one
if there is one, else on the next monitor.  With one monitor, return nil."
  (let* ((monitors (display-monitor-attributes-list))
         (portrait-p (lambda (monitor)
                       (pcase-let ((`(,_ ,_ ,width ,height)
                                    (alist-get 'geometry monitor)))
                         (> height width))))
         (editor (car (or (seq-remove portrait-p monitors) monitors)))
         (others (remq editor monitors))
         (panels (or (seq-find portrait-p others) (car others))))
    (when panels (cons editor panels))))

(defun +sf/frame-position (monitor)
  "Frame parameters putting a frame at the top left of MONITOR.
\(+ N) is an absolute position, even when N is negative."
  (pcase-let ((`(,x ,y . ,_) (alist-get 'workarea monitor)))
    `((left . (+ ,x)) (top . (+ ,y)) (user-position . t))))

(defun +sf/place-frame (frame monitor)
  "Move FRAME to MONITOR unless it is already there, and maximize it."
  (unless (equal (alist-get 'geometry (frame-monitor-attributes frame))
                 (alist-get 'geometry monitor))
    (set-frame-parameter frame 'fullscreen nil)  ; a maximized frame won't move
    (modify-frame-parameters frame (+sf/frame-position monitor)))
  (set-frame-parameter frame 'fullscreen 'maximized))

(defun +sf/panel-kind (buffer)
  "Which panel BUFFER is: `tree', `outline', `term', or nil."
  (let ((name (buffer-name buffer)))
    (cond ((and (boundp 'treemacs-buffer-name-prefix)
                (string-prefix-p treemacs-buffer-name-prefix name))
           'tree)
          ((equal name "*Ilist*") 'outline)
          ((string-match-p "ghostel" name) 'term))))

(defun +sf/display-panel (buffer _alist)
  "Show panel BUFFER in its place in the panel frame.
The file tree goes top left, the outline top right, the terminal across the
bottom half; a window that shows no panel is used first.  For use in
`display-buffer-overriding-action': BUFFERs that aren't panels are left to
the other display actions.

The display ALIST is ignored: it also holds the sizes and window parameters
of the other actions, such as Doom's popup rule for the terminal (35% of the
frame), which would undo the even split."
  (when-let* ((kind (+sf/panel-kind buffer))
              ((frame-live-p +sf-panel-frame)))
    (or (get-buffer-window buffer +sf-panel-frame)
        (let* ((windows (window-list +sf-panel-frame 'nomini))
               (find (lambda (k)
                       (seq-find (lambda (w) (eq k (+sf/panel-kind (window-buffer w))))
                                 windows)))
               (spare (funcall find nil))
               (tree (funcall find 'tree))
               (outline (funcall find 'outline))
               (term (funcall find 'term))
               (window
                (cond (spare)
                      ((eq kind 'term)
                       (split-window (frame-root-window +sf-panel-frame) nil 'below))
                      ((and (eq kind 'tree) outline) (split-window outline nil 'left))
                      ((and (eq kind 'outline) tree) (split-window tree nil 'right))
                      (term (split-window term nil 'above)))))
          (when window
            (prog1 (window--display-buffer buffer window (if spare 'reuse 'window) nil)
              (set-window-dedicated-p window t)))))))

(defun +sf/in-panel-frame-a (fn &rest args)
  "Run FN in the panel frame, for the current buffer, if there is one.
Panels FN displays go to their places there."
  (if (+sf/two-frames-p)
      (let ((buffer (current-buffer))
            (display-buffer-overriding-action '((+sf/display-panel))))
        (with-selected-frame +sf-panel-frame
          (with-current-buffer buffer
            (apply fn args))))
    (apply fn args)))
(advice-add #'+treemacs/toggle :around #'+sf/in-panel-frame-a)
(advice-add #'imenu-list-smart-toggle :around #'+sf/in-panel-frame-a)

;; The terminal (C-c o t).  Two frames: the bottom half of the panel frame,
;; selected when it opens.  One frame: Doom's popups always span the whole frame
;; width, ignoring `window-sides-vertical', so show it as a plain bottom side
;; window instead: it then sits under the editor only, like VS Code's terminal
;; panel.
(defadvice! +sf/ghostel-placement-a (fn &rest args)
  :around #'+ghostel/toggle
  (if (+sf/two-frames-p)
      (let ((term (apply #'+sf/in-panel-frame-a fn args)))
        (when-let* ((window (and (bufferp term)
                                 (get-buffer-window term +sf-panel-frame))))
          (select-frame-set-input-focus +sf-panel-frame)
          (select-window window))
        term)
    (let ((display-buffer-overriding-action
           '((display-buffer-in-side-window)
             (side . bottom) (slot . 0) (window-height . 0.3)
             (preserve-size . (nil . t)))))
      (apply fn args))))

(defun +sf/editor-window ()
  "The editing window of the editor frame used most recently."
  (car (sort (seq-remove (lambda (w) (or (window-dedicated-p w)
                                         (window-parameter w 'window-side)))
                         (window-list +sf-editor-frame 'nomini))
             (lambda (a b) (> (window-use-time a) (window-use-time b))))))

(defun +sf/show-files-in-editor-frame (buffer alist)
  "From the panel frame, show file and directory BUFFERs in the editor frame."
  (when-let* (((+sf/two-frames-p))
              ((eq (selected-frame) +sf-panel-frame))
              ((with-current-buffer buffer
                 (or buffer-file-name (derived-mode-p 'dired-mode))))
              (window (or (get-buffer-window buffer +sf-editor-frame)
                          (+sf/editor-window))))
    ;; `pop-to-buffer' (find-file, the tree, the outline) then moves the focus
    ;; to the editor frame; `display-buffer' leaves it in the panel frame.
    (window--display-buffer buffer window 'reuse alist)))
(setq display-buffer-overriding-action '((+sf/show-files-in-editor-frame)))

;; Treemacs keeps a tree per frame and looks for it in the selected frame only.
;; Give all frames the panel frame's tree, so it follows the project of the
;; file in the editor frame.
(after! treemacs
  (defadvice! +sf/treemacs-panel-frame-scope-a (fn scope-type)
    :around #'treemacs-scope->current-scope
    (if (and (+sf/two-frames-p) (eq scope-type 'treemacs-frame-scope))
        +sf-panel-frame
      (funcall fn scope-type)))
  (defadvice! +sf/treemacs-panel-frame-window-a (fn)
    :around #'treemacs-get-local-window
    (or (funcall fn)
        (and (+sf/two-frames-p)
             (seq-find (lambda (w) (eq 'tree (+sf/panel-kind (window-buffer w))))
                       (window-list +sf-panel-frame 'nomini))))))

;; Closing the editor frame from the window manager quits Emacs, as closing the
;; single frame did; the panel frame alone is no use.
(defadvice! +sf/quit-with-editor-frame-a (fn event)
  :around #'handle-delete-frame
  (if (and (+sf/two-frames-p)
           (eq (posn-window (event-start event)) +sf-editor-frame))
      (save-buffers-kill-emacs)
    (funcall fn event)))

(defun +sf/two-frame-layout (monitors)
  "Build the two-frame layout on MONITORS, (EDITOR-MONITOR . PANEL-MONITOR)."
  (require 'treemacs)
  ;; Treemacs goes in an ordinary window of the panel frame, at whatever width
  ;; the layout gives it.
  (setq treemacs-display-in-side-window nil
        treemacs-width-is-initially-locked nil)
  (let ((editor (selected-window)))
    (setq +sf-editor-frame (selected-frame))
    (+sf/place-frame +sf-editor-frame (car monitors))
    (unless (frame-live-p +sf-panel-frame)
      (setq +sf-panel-frame
            (make-frame `((name . "Doom panels")
                          (fullscreen . maximized)
                          ,@(+sf/frame-position (cdr monitors))))))
    ;; Clear the panel frame down to one spare window, then fill it.
    (with-selected-frame +sf-panel-frame
      (let ((ignore-window-parameters t))  ; Treemacs refuses to be deleted
        (delete-other-windows))
      (set-window-dedicated-p nil nil)
      (switch-to-buffer (get-buffer-create " *panels*") t t))
    (with-selected-window editor
      (+treemacs/toggle))
    (with-selected-window editor
      (imenu-list-smart-toggle))
    (with-selected-window editor
      (+ghostel/toggle))
    (select-frame-set-input-focus +sf-editor-frame)
    (select-window editor)
    (setq claude-code-ide-window-width (/ (frame-width) 3))
    (claude-code-ide)))

(defun +sf/one-frame-layout ()
  "Open file tree, outline, terminal and Claude around the current buffer."
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

;; One command for the whole VS Code-like layout: two frames with two monitors,
;; else one frame with the file tree and outline on the left, the terminal
;; under the editor and Claude on the right.  C-c o l.
(defun +sf/ide-layout ()
  "Lay out the editor, Claude, file tree, outline and terminal."
  (interactive)
  (if-let* ((monitors (+sf/monitors)))
      (+sf/two-frame-layout monitors)
    (+sf/one-frame-layout)))
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
;;
;; KDE takes Ctrl+F1..F12 for switching desktops, so PyCharm's C-<f8> and
;; C-<f2> never reach Emacs.  They stay bound (they work if KDE lets go of
;; them), with stand-ins: Eclipse's C-S-b and VS Code's S-<f5>.
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
        "C-S-b"   #'dape-breakpoint-toggle
        "C-<f2>"  #'dape-quit                 ; Stop
        "S-<f5>"  #'dape-quit)
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
  ;; The program's output goes to the REPL, as in PyCharm's debug console,
  ;; rather than to a *dape-shell* terminal of its own (which would need a
  ;; fourth panel).  The price: the program can't read stdin (`input()').
  ;; debugpy then reports each line twice, once from the program's stdout pipe
  ;; and once more from inside the program (`redirectOutput', on by default
  ;; with this console); the pipe alone still arrives live.
  (dolist (key '(debugpy debugpy-module))
    (plist-put (alist-get key dape-configs) 'command "python3")
    (plist-put (alist-get key dape-configs) :python #'+sf/python-executable)
    (plist-put (alist-get key dape-configs) 'ensure #'+sf/debugpy-ensure)
    (plist-put (alist-get key dape-configs) :console "internalConsole")
    (plist-put (alist-get key dape-configs) :redirectOutput :json-false))

  ;; PyCharm's Debug tool window: a strip under the editor with the call stack
  ;; (TAB cycles through Breakpoints, Threads, Modules, Sources), the variables
  ;; (TAB: Watch) and the REPL.  dape's own arrangements put its panels in the
  ;; left or right side-window slots, where the file tree, outline and Claude
  ;; already live, and evict them.  With no arrangement dape leaves placement
  ;; to `display-buffer-alist', tagging each info group with the `category'
  ;; dape-info-<group index>.
  (setq dape-buffer-window-arrangement nil
        dape-info-buffer-window-groups
        '((dape-info-stack-mode dape-info-breakpoints-mode dape-info-threads-mode
           dape-info-modules-mode dape-info-sources-mode)
          (dape-info-scope-mode dape-info-watch-mode)))
  (pcase-dolist (`(,condition . ,slot) '(((category . dape-info-0) . -1)
                                         ((category . dape-info-1) . 0)
                                         ("\\`\\*dape-repl\\*\\'" . 1)))
    (add-to-list 'display-buffer-alist
                 `(,condition
                   (display-buffer-reuse-window display-buffer-in-side-window)
                   (side . bottom) (slot . ,slot) (window-height . 0.3)
                   (preserve-size . (nil . t)))))

  ;; The terminal lives in that strip too: it steps aside when a session
  ;; starts and comes back once dape quits (which kills the REPL).  The
  ;; restore waits for dape to finish killing its buffers, so the terminal
  ;; doesn't land in a panel window that is about to close.
  (defvar +sf/dape-hid-terminal nil
    "Non-nil while a dape session has put the terminal aside.")
  (defun +sf/dape-hide-terminal-h ()
    (dolist (window (window-list))
      (when (string-match-p "ghostel" (buffer-name (window-buffer window)))
        (delete-window window)
        (setq +sf/dape-hid-terminal t))))
  (defun +sf/dape-restore-terminal-h ()
    (when +sf/dape-hid-terminal
      (setq +sf/dape-hid-terminal nil)
      (run-at-time 0 nil (lambda () (save-selected-window (+ghostel/toggle))))))
  (defun +sf/dape-watch-repl-h ()
    (add-hook 'kill-buffer-hook #'+sf/dape-restore-terminal-h nil t))
  (add-hook 'dape-start-hook #'+sf/dape-hide-terminal-h -90)  ; before the panels open
  (add-hook 'dape-repl-mode-hook #'+sf/dape-watch-repl-h))

;; Doom's popup catch-all ("^\\*") would otherwise turn these buffers into
;; bottom popups; let the packages manage their own side windows instead.
(set-popup-rule! "^\\*claude-code\\[" :ignore t)
(set-popup-rule! "^\\*Ilist\\*" :ignore t)

;; Printing (M-x print-buffer, lpr-region, ps-print-buffer, P in dired): the
;; Brother laser on USB, passed to lpr as -P.  Without it lpr falls back to
;; CUPS's default printer, which may be unset or stale.
(setq printer-name "Brother_Polus"
      ps-printer-name nil)                ; nil: follow `printer-name'


;; Export from markdown to lualatex
;; With mathfont set, pandoc's template loads unicode-math
;; and fontspec under \ifLuaTeX/\ifXeTeX guards,
;; so the file works when you compile with lualatex.
;; (after! markdown-mode
;;  (setq markdown-command
;;        "pandoc -f markdown -t latex -s -V mainfont='Minion Pro' sanseriffont='Myriad Pro' -V mathfont='Libertinus Math'"))

;; view markdown in browser
(defun my/markdown-preview-html ()
  "Preview the markdown buffer as HTML in the browser."
  (interactive)
  (let ((markdown-command "pandoc -f gfm -t html5 -s"))
    (markdown-preview)))

;; Live preview (C-c C-c l) renders in eww, in its own Emacs frame.
;; An entry in `display-buffer-alist' does not survive Doom's popup
;; system (+popup-mode replaces the alist), so override the function
;; markdown-mode uses to show the preview instead.  Reuses the preview
;; frame if it is already open.
(after! markdown-mode
  (defadvice! my/markdown-preview-in-own-frame (buf)
    :override #'markdown-display-buffer-other-window
    (display-buffer buf '((display-buffer-reuse-window display-buffer-pop-up-frame)
                          (reusable-frames . t)
                          (inhibit-same-window . t)))))

;; After C-x 5 0 the "Close frame? (y or n)" prompt, already answered
;; in the closed frame, lingers in the main frame's echo area and looks
;; like a second prompt; keys typed at it go to the focused buffer.
;; Clear the echo area once a frame is gone.
(defun my/clear-echo-area-after-frame-delete (_frame)
  (run-at-time 0 nil (lambda () (message nil) (redraw-display))))
(add-hook 'after-delete-frame-functions #'my/clear-echo-area-after-frame-delete)

;; Close frames without confirmation: undo Doom's remap of `delete-frame'
;; to `doom/delete-frame-with-prompt'.  Plain `delete-frame' refuses to
;; delete the last frame, so C-x 5 0 cannot quit Emacs by accident.
(global-set-key [remap delete-frame] nil)

;Alternative leader key
;(setq doom-leader-alt-key "<f8>"
;      doom-localleader-alt-key "<f8> m")

(after! evil
  (setq evil-default-state 'emacs))

;; Evil stays loaded only for Doom's leader menu (M-SPC); editing is modeless.
;; C-z, evil's toggle key, would switch from Emacs state to vi's Normal state,
;; where letters are commands.  Make C-z undo instead, as in other apps, and
;; let it lead only back to Emacs state from the vi states, should a buffer
;; ever start in one.
(map! :after evil
      :map evil-emacs-state-map
      "C-z" #'undo)
(map! :after evil
      :map (evil-normal-state-map evil-motion-state-map
            evil-insert-state-map evil-visual-state-map)
      "C-z" #'evil-emacs-state)

;; pdf-tools printing (C-c C-p): use lpr to the default CUPS printer
;; instead of prompting for a print program every time.
(after! pdf-misc
  (setq pdf-misc-print-program-executable "/usr/bin/lpr"
        pdf-misc-print-program-args '("-o" "sides=two-sided-long-edge")))


;; set okular as preferred pdf viewer for latex,
;; fall back to pdf tools if okular fails
;; LaTeX: view PDFs in Okular rather than Evince.
(setq +latex-viewers '(okular pdf-tools))

;; LaTeX: compile with LuaLaTeX by default.
(after! tex
  (setq-default TeX-engine 'luatex))


;; Live preview (latexmk -pvc) with LuaLaTeX too.
(setq auctex-cont-latexmk-command
      '("latexmk -pvc -lualatex -view=none -e "
        ("$lualatex=q/lualatex %O -synctex=1 -file-line-error -interaction=nonstopmode %S/")))
