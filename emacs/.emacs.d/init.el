;;;; EMACS UNIFIED CONFIGURATION FILE
;;;;
;;;; This file is my current Emacs configuration as used on all machines over
;;;; which I have control. All external dependencies are managed via USE-PACKAGE,
;;;; so it should be sufficient to drop this file and the others listed below in
;;;; ~/.emacs.d and start Emacs in order to initialise the configuration.
;;;;
;;;; The following files are required for this configuration to load
;;;; successfully, where all paths are relative to ~/.emacs.d:
;;;;
;;;;   - init.el (this file)
;;;;   - elisp/ligature.el
;;;;   - fortunes/lambda.txt
;;;;
;;;; Copyright (c) 2022, Andrew Smith <aws@awsmith.us>
;;;; SPDX-License-Identifier: MIT

;;; Increase the garbage collector threshold to 10 MB to speed up the startup
;;; process. Once initialisation is complete, decrease it to a slightly more
;;; reasonable value.
(setq gc-cons-threshold 10000000)
(add-hook 'after-init-hook
          (lambda () (setq gc-cons-threshold 1000000)))

;;; Initialise the package manager using packages both from the official ELPA
;;; repo and the unofficial (but community-standard) MELPA.
(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

;;; I also use a number of Elisp scripts that are not distributed via (M)ELPA;
;;; we shall load these from a local directory.
(defvar awsmith/elisp-path '("~/.emacs.d/elisp"))
(mapcar #'(lambda (p) (add-to-list 'load-path p)) awsmith/elisp-path)

;;; Bootstrap quelpa and quelpa-use-package to allow packages to be installed
;;; directly from their upstream Git repositories.
(require 'quelpa)
(quelpa
 '(quelpa-use-package
   :fetcher git
   :url "https://github.com/quelpa/quelpa-use-package.git"))
(require 'quelpa-use-package)

;;; Install use-package, which we shall use to install and configure all
;;; remaining packages.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(setq use-package-always-ensure t) ; Always verify successful installation.

;;; Load delight as a dependency of use-package in order to hide most minor modes
;;; from the modeline.
(use-package delight)

;;; Use Company to provide autocompletion. Later, when configuring LSP, we shall
;;; set it to display its completions using Company as well.
(use-package company
  :delight
  :config (global-company-mode))

;;; Many LSP language modes require the ability to execute shell commands, many
;;; of which rely upon the use of tools distributed with the respective languages
;;; to properly configure the environment. Let's set the exec-path directly from
;;; the shell so that it includes these tools regardless of how Emacs is run.
(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;;; Many language-specific packages rely upon LSP (Language Server Protocol)
;;; support, so let's install and configure that package before the other
;;; packages' dependency resolution begins.
(use-package lsp-mode
  :init
  ;; Disable minibuffer signature delay: superseded by lsp-ui-doc.
  (setq lsp-signature-auto-activate nil
        lsp-signature-render-documentation nil
        lsp-headerline-breadcrumb-enable nil ; Disable breadcrumb bar.
        lsp-ui-peek-enable nil               ; Disable lsp-peek entirely.
        lsp-ui-doc-show-with-cursor t)       ; Display documentation in a posframe.
  :custom
  (lsp-idle-delay 0.6)
  ;; Add some additional UI features that integrate with LSP.
  (use-package lsp-ui))

;;; Flycheck is another common dependency for error display.
(use-package flycheck)

;;; I was an early convert to the Church of Modal Editing, so evil-mode is a
;;; must. I've also modified some evil-mode behaviours to more closely match
;;; vim, since I still often find myself using vim over SSH when TRAMP is
;;; verboten by organisational policy.
(use-package evil
  :init
  (setq evil-shift-round nil        ; Don't break Lisp indentation.
        evil-undo-system 'undo-redo ; Use Emacs's built-in redo functionality.
        evil-vsplit-window-right t  ; Open new vertical splits to the right.
        evil-split-window-below t   ; ...and horizontal splits below the current.
        evil-want-C-u-scroll t)     ; Use C-u to scroll up half a page.
  :config
  (evil-mode)                       ; Enable evil-mode in all buffers.
  ;; Emulate commenary.vim, which adds a command <gc> to (un-)comment lines.
  (use-package evil-commentary :config (evil-commentary-mode 1))
  ;; Provide some additional ex-mode commands beyond those provided by evil.
  (use-package evil-expat)
  ;; Emulate quick-scope.vim, which highlights target characters for <FfTt>.
  (use-package evil-quickscope
    :config
    (global-evil-quickscope-mode 1)
    ;; Make the highlighted characters stand out a bit more.
    (set-face-attribute 'evil-quickscope-first-face nil
                        :background "khaki"
                        :foreground "black"
                        :underline t
                        :weight 'bold)
    (set-face-attribute 'evil-quickscope-second-face nil
                        :background "sandy brown"
                        :foreground "black"
                        :underline t
                        :weight 'bold))
  ;; Emulate surround.vim, which adds a motion <s> to modify paired delimiters.
  (use-package evil-surround :config (global-evil-surround-mode 1)))

;;; Minibuffer completion and enhancements for interactive commands that
;;; typically conduct interaction within the minibuffer.
(use-package counsel
  ;; Use C-p to select the current input rather than the first completion.
  :init (setq ivy-use-selectable-prompt t)
  :bind (("C-s" . swiper-isearch)
         ("M-x" . counsel-M-x)
         ("C-x C-f" . counsel-find-file)
         ("C-h f" . counsel-describe-function)
         ("C-h v" . counsel-describe-variable)
         ("C-c o" . counsel-outline)
         ("C-c C-r" . ivy-resume)
         :map ivy-minibuffer-map
         ("<return>" . ivy-alt-done)) ; Make <return> behave as expected.
  :delight ivy-mode
  :config
  (ivy-mode)
  (setq ivy-count-format "(%d/%d) "   ; Include the total count in ivy lists.
        ivy-initial-inputs-alist nil) ; Don't start ivy completions with ^.
  ;; Display ivy completions at the center of the frame.
  (use-package ivy-posframe
    :delight
    :config
    (ivy-posframe-mode)
    (setq ivy-posframe-display-functions-alist
          '((t . ivy-posframe-display-at-frame-center)))))

;;; Git interaction via magit, so I can utilise the mental space that would have
;;; been occupied by arcane Git incantations for more useful information.
(use-package magit
  :bind ("C-c g" . magit-status))

;;; Let's also show the current git diff in the fringe to gain a quick overview
;;; of the current version control status of a file.
(use-package git-gutter-fringe
  :delight git-gutter-mode
  :config
  ;; Render diff symbols in the mostly empty right fringe.
  (setq git-gutter:update-interval 1
        git-gutter-fr:side 'right-fringe)
  ;; Define some less obtrusive diff indicators.
  (fringe-helper-define 'git-gutter-fr:added '(center repeated)
    "XXX.....")
  (fringe-helper-define 'git-gutter-fr:modified '(center repeated)
    "XXX.....")
  (fringe-helper-define 'git-gutter-fr:deleted 'bottom
    "X......."
    "XX......"
    "XXX....."
    "XXXX....")
  (global-git-gutter-mode))

;;; Load the OS1 theme, which has not been publicly released on MELPA yet. I've
;;; left this theme in my configuration because I think that it will develop
;;; quite well in the future, but I'm not ready to use it daily yet.
(use-package os1-theme
  :quelpa (os1-theme :fetcher github :repo "sashimacs/os1-theme")
  :defer nil
  :config
  (setq os1-modeline-padding 1
        os1-use-less-bold t
        os1-use-more-italic t))

;;; I currently use two themes from the ef-themes package, which contains
;;; aesthetic variants of the Modus themes with modified contrast ratios:
;;; ef-cyprus as a light theme, and ef-autumn as a dark theme. These themes are
;;; almost direct inverses of each other, providing some pleasant contrast at
;;; different light levels.
(use-package ef-themes
  :ensure t
  :config
  (setq ef-themes-region '(intense))
  (load-theme 'ef-cyprus t)
  ;; (load-theme 'ef-autumn t)
  (set-face-attribute 'bold nil :weight 'semi-bold))

;;; Nyan Cat in the minibuffer! This is admittedly fairly stupid, but a
;;; screenshot of this mode was the impetus for my initial switch to Emacs while
;;; on vacation in Houston in 2014. As a previously staunch "Vim in TTY"
;;; adherent, seeing a simple demo of Emacs's graphical capabilities was enough
;;; to pique my curiosity while I had some free time, and now here we are.
(use-package nyan-mode
  :config
  (nyan-mode)
  (setq nyan-bar-length 16))

;;; Highlight matching pairs of delimiters in cyclic colours within all
;;; programming modes.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;; Enable the use of custom code formatters, on which I have become wholly
;;; dependent for even the most basic of formatting, directly from Emacs.
(use-package reformatter
  :config
  (reformatter-define ocaml-format
    :program "ocamlformat"
    :args (list "--name" (buffer-file-name) "-")))

;;; Use SLIME to provide interaction with my Lisp interpreter of choice, SBCL.
(use-package slime
  :config
  (setq inferior-lisp-program "sbcl")
  (slime-setup '(slime-fancy slime-company))
  ;; Provide SLIME completion suggestions via Company.
  (use-package slime-company
    :after (slime company)
    :config (setq slime-company-completion 'fuzzy)))

;;; Use Tuareg to provide language-specific features for OCaml and enable
;;; ocaml-lsp to run in OCaml files.
(use-package tuareg
  :hook (tuareg-mode . lsp)
  :bind (:map tuareg-mode-map
         ("C-c f" . ocaml-format-buffer))
  :config
  (set-face-attribute 'tuareg-font-lock-constructor-face nil
                      :inherit 'font-lock-constant-face
                      :foreground 'unspecified))

;;; Suggest completions for the key sequence currently in progress.
(use-package which-key
  :delight
  :hook (after-init . which-key-mode)
  :config
  ;; Display completions in a posframe at the center of the frame.
  (use-package which-key-posframe
    :config
    (which-key-posframe-mode)
    (setq which-key-posframe-poshandler 'posframe-poshandler-frame-center)))

;;; Set the default font to Iosevka Collegiate, my custom variation of Iosevka
;;; available at https://gist.github.com/Andrew-William-Smith/3d455d43ecd7780945269e5b6091882f
(set-face-attribute 'default nil
                    :family "Iosevka Collegiate"
                    :height (if (eq system-type 'darwin) 140 120))
(if (eq system-type 'darwin)
    ;; Enable font ligatures on macOS (emacs-mac-port).
    (mac-auto-operator-composition-mode)
  ;; Ligatures on other platforms are provided by the local package "ligature".
  ;; Emacs must be compiled with Harfbuzz support for this to work properly.
  (use-package ligature
    :config
    ;; Enumeration of ligatures provided by Iosevka.
    (ligature-set-ligatures 't '("-<<" "-<" "-<-" "<--" "<---" "<<-" "<-"
                                 "->" "->>" "-->" "--->" "->-" ">-" ">>-"
                                 "<->" "<-->" "<--->" "<---->" "<!--"
                                 "=<<" "=<" "=<=" "<==" "<===" "<<=" "<="
                                 ">=" "=>>" "==>" "===>" "=>=" ">=" ">>="
                                 "<=>" "<==>" "<===>" "<====>" "<!---"
                                 "[|" "|]" "{|" "|}"
                                 "<=<" ">=>" "<~" "<~~" "~>" "~~>"
                                 "::" ":::" "\\/" "/\\" "==" "!=" "<>"
                                 "===" "!==" "=/=" "=!="
                                 ":>" ":=" ":-" ":+" "+:" "-:" "=:"
                                 "<*" "<*>" "*>" "<|" "<|>" "|>" "<." "<.>" ".>"
                                 "<***>" "__" "(*" "*)" "++" "+++" "|-" "-|"))
    (global-ligature-mode 1)))

;;; In all new buffers, set the encoding to UTF-8 and use Unix-style (LF) line
;;; endings, regardless of the host platform. *Sad Windows noises*
(setq-default buffer-file-coding-system 'utf-8-unix
              require-final-newline t)

;;; By default, opening a new buffer places that buffer in Fundamental mode.
;;; Since Fundamental mode disables nearly all minor modes, it is functionally
;;; useless to me: as such, we shall start buffers in text-mode instead.
(setq-default major-mode 'text-mode)

;;; Whitespace control. Note that some modes may ignore or override these
;;; settings: these modes will require custom hooks when discovered.
(setq-default indent-tabs-mode nil       ; Indent using "soft" (space) tabs.
              show-trailing-whitespace t ; Highlight trailing whitespace.
              tab-width 4)               ; Use a width of 4 for soft tabs.

;;; Let's indent new lines by default in all modes to save myself some spacebar
;;; mashing. Alignment is useful outside of programming!
(global-set-key (kbd "RET") 'newline-and-indent)

;;; Enable line numbers for all buffers. Lines are counted relative to the
;;; current line to faciliate the use of evil's counted motions, although the
;;; absolute index is displayed for the current line, which is highlighted.
(setq-default display-line-numbers-current-absolute t
              display-line-numbers-type 'relative
              display-line-numbers-width 3
              display-line-numbers-widen t)
(global-display-line-numbers-mode)
(global-hl-line-mode)

;;; Also display a line at the fill column, which is set to column 80 in buffers
;;; that do not specify a different column in their file-local variables.
(setq-default fill-column 80)
(global-display-fill-column-indicator-mode)

;;; Custom mode-line format. This is perpetually subject to change, although the
;;; general format should remain relatively static: a series of block characters
;;; showing properties of the current buffer, followed by the buffer name,
;;; followed by minor mode information. A solid block at the beginning of the
;;; mode-line signifies the "default" state of the buffer: normal mode, writable,
;;; with no unsaved changes.
(defconst +awsmith/mode-line-indicator-evil-symbols+
  '((normal   . "█")
    (insert   . "▟")
    (replace  . "▚")
    (visual   . "▜")
    (operator . "▓")))

(defun awsmith/mode-line-indicator-evil ()
  "Get the mode-line indicator block corresponding to the current evil-mode
state, or a designated symbol if evil-mode is disabled."
  (let ((indicator (assoc evil-state +awsmith/mode-line-indicator-evil-symbols+)))
    (if indicator
        (propertize (cdr indicator)
                    'help-echo (concat (symbol-name evil-state) " mode"))
      (propertize "░" 'help-echo "evil-mode inactive"))))

(defun awsmith/mode-line-buffer-directory ()
  "Format the directory to which the file opened in the current buffer belongs
such that each directory is truncated to a single distinguishing character. If
the current buffer is not backed by a file, this function returns NIL."
  (when (buffer-file-name)
    (concat
     (mapconcat 'identity
      (mapcar
       ;; Truncate the directory name to a single character, or two characters if
       ;; the directory name begins with a dot.
       (lambda (dir)
         (let ((dir-substring-length (if (string-prefix-p "." dir) 2 1)))
           (propertize (substring dir 0 dir-substring-length) 'help-echo dir)))
       (butlast (split-string
                 (replace-regexp-in-string (getenv "HOME") "~" default-directory)
                 "/")))
      "/")
     "/")))

(defun awsmith/mode-line-codepoint ()
  "Return a formatted display of the Unicode codepoint of the character at the
current point, provided that it is outside the standard visible ASCII range.
Returns NIL for characters in this range."
  (when (char-after)
    (let ((code-at-point (encode-char (char-after) 'unicode)))
      (when (and (not (< 32 code-at-point 127)) ; Ignore visible ASCII characters
                 (/= code-at-point 10)          ; ...and newlines
                 (/= code-at-point 32))         ; ...and spaces.
        (format " U+%04X %s"
                code-at-point
                (get-char-code-property code-at-point 'name))))))

(defconst +awsmith/mode-line-separator+ " │ ")

(setq-default mode-line-format
              '((:eval (awsmith/mode-line-indicator-evil))
                (:eval (if buffer-read-only
                           (propertize "░" 'help-echo "Buffer is read-only")
                         (propertize "█" 'help-echo "Buffer is writable")))
                (:eval (if (buffer-modified-p)
                           (propertize "░" 'help-echo "Buffer has unsaved changes")
                         (propertize "█" 'help-echo "Buffer is saved")))
                " "
                (:eval (awsmith/mode-line-buffer-directory))
                (:eval (propertize "%b" 'face 'bold 'help-echo (buffer-file-name)))
                (:eval (when (vc-backend (buffer-file-name))
                         (concat ":" (car (vc-git-branches)))))
                (:eval +awsmith/mode-line-separator+)
                (:eval (list (nyan-create)))
                (:eval +awsmith/mode-line-separator+)
                (:eval mode-name)
                (:eval " (%l,%c")
                (:eval (awsmith/mode-line-codepoint))
                ")"
                (:eval +awsmith/mode-line-separator+)
                (:eval (format-mode-line minor-mode-alist))))

;;; Show the boundaries of the current buffer in the right fringe.
(setq-default indicate-buffer-boundaries 'right)

;;; Highlight matching parentheses when the point is over one.
(show-paren-mode)

;;; Disable unnecessary UI elements.
(scroll-bar-mode -1)
(tool-bar-mode -1)
(setq-default inhibit-splash-screen t ; Don't show the splash screen at startup.
              ring-bell-function nil  ; Stop beeping at me!
              use-dialog-box nil)     ; Show Y-OR-N-P prompts in the minibuffer.

;;; Make the default frame a bit larger in GUI sessions.
(when window-system
  (set-frame-size (selected-frame) 120 36))

;;; Enable pixel scrolling in Emacs 29. We opt out of Emacs' built-in
;;; functionality when running emacs-mac-port since it provides its own pixel
;;; scrolling that integrates better with macOS.
(unless (or (eq system-type 'darwin)
            (version< emacs-version "29.0.50"))
  (pixel-scroll-precision-mode))

;;; A simple reimplementation of the fortune command, because why not?
(defvar awsmith/fortune-default-file "~/.emacs.d/fortunes/lambda.txt")
(defun awsmith/fortune (&optional fortune-file line-prefix)
  "Display a random fortune from the specified FORTUNE-FILE, with each line
prefixed with the specified LINE-PREFIX. The format of fortune files is
relatively simple: fortunes are separated by percent signs on their own lines,
and the first fortune is considered informational and is thus discarded.
Informational fortunes are, of course, of no utility to us."
  (interactive)
  (let* ((real-file (or fortune-file awsmith/fortune-default-file))
         (real-line-prefix (or line-prefix ""))
         (fortunes (cdr (split-string
                         (with-temp-buffer
                           (insert-file-contents real-file)
                           (buffer-string))
                         "\n%\n" t "\n")))
         ;; Pick a random fortune from the file.
         (selected (nth (random (length fortunes)) fortunes))
         (prefixed (mapconcat
                    (lambda (line) (concat real-line-prefix line))
                    (split-string selected "\n")
                    "\n")))
    (when (called-interactively-p 'interactive)
      (message prefixed))
    prefixed))

;;; Change the default message displayed in scratch buffers to be a bit more
;;; informative and attractive.
(setq initial-scratch-message
      (format ";; ╔══════════════════════════════════════════════════╤════════════════════╗
;; ║ EMACS SCRATCH BUFFER                             │ GNU Emacs %-8s ║
;; ╟──────────────────────────────────────────────────┴────────────────────╢
;; ║ This buffer is for text that is not saved, and for Lisp evaluation.   ║
;; ║ To create a file, visit it with C-x C-f and enter text in its buffer. ║
;; ║                                                                       ║
;; ║ evil-mode is currently active.  Use vim keybindings for navigation.   ║
;; ╚═══════════════════════════════════════════════════════════════════════╝
;;
;; ══════════════════ THUS SAITH THE WISDOM OF THE ELDERS ══════════════════
%s\n\n"
              emacs-version
              (awsmith/fortune awsmith/fortune-default-file ";; ")))

;;; Make all Customize changes ephemeral by writing them to a temporary file
;;; rather than this file.
(setq custom-file (make-temp-file "customize-variables"))

;;; Speaking of files, Emacs's backup files are useful, but allowing them to
;;; litter every directory is quite annoying. Let's centralise them to a single
;;; directory in .emacs.
(setq backup-directory-alist '(("." . "~/.emacs.d/backup"))
      backup-by-copying t   ; Copy backups rather than linking them.
      delete-old-versions t ; Silently delete old backups per the version counts.
      kept-new-versions 20
      kept-old-versions 5
      version-control t)    ; Add version numbers to backup filenames.

;;; We don't want to override the default distribution's org-mode package by
;;; installing it from ELPA, but we still need to customise a number of
;;; behaviours, configured outside of their respective package below.
(setq org-directory "~/org"                            ; Store all org-mode files in ~/org.
      org-agenda-files '("~/org")
      org-agenda-start-on-weekday nil                  ; Always start timeline on current day.
      org-agenda-tags-todo-honor-ignore-options t      ; Always hide ignored options.
      org-agenda-skip-deadline-if-done t               ; Hide completed deadlines.
      org-agenda-skip-scheduled-if-done t              ; ...and scheduled events.
      org-deadline-warning-days 7                      ; Only warn about deadlines in future weeks.
      org-agenda-todo-ignore-deadlines 'near           ; Don't repeat deadlines on the current day.
      org-agenda-start-with-log-mode t                 ; Show clock summary.
      org-agenda-log-mode-items '(closed clock state)) ; ...containing all items.
(global-set-key "\C-ca" 'org-agenda)
