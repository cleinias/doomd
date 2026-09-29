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
        claude-code-ide-window-width 100)
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

;; Left and right side windows (file tree, outline, Claude) take the full
;; frame height, so the bottom terminal popup spans only the editor area.
(setq window-sides-vertical t)

;; One command for the whole VS Code-like layout: file tree + outline on the
;; left, terminal under the editor, Claude on the right.  C-c o l.
(defun +sf/ide-layout ()
  "Open file tree, outline, terminal and Claude around the current buffer."
  (interactive)
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

;; Make it the default: the first time a project file is opened in a workspace,
;; set up the layout once.  Remembered per workspace, so panes you close
;; yourself stay closed; C-c o l brings them back.
(defun +sf/ide-layout-maybe-h ()
  (when (and buffer-file-name
             (doom-project-p)
             (bound-and-true-p persp-mode)
             (not (persp-parameter '+sf-ide-layout)))
    (set-persp-parameter '+sf-ide-layout t)
    (run-at-time 0 nil #'+sf/ide-layout)))
(add-hook 'find-file-hook #'+sf/ide-layout-maybe-h)

;; Doom's popup catch-all ("^\\*") would otherwise turn these buffers into
;; bottom popups; let the packages manage their own side windows instead.
(set-popup-rule! "^\\*claude-code\\[" :ignore t)
(set-popup-rule! "^\\*Ilist\\*" :ignore t)
