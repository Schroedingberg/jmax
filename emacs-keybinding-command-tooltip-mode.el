;;; emacs-keybinding-command-tooltip-mode.el --- A minor mode for emacs commands and keybindings

;;; Commentary:
;; Makes the syntax \\[some-command] and `some-command' functional in a buffer.


;;; Code:

(require 'rx)

(defvar elisp-symbol-keybinding-re
  (rx
   ;; opening \\[
   (eval "\\[")
   ;; one or more characters that are not ]
   (group (one-or-more (not (any "]"))))
   ;; The closing ]
   "]")
"Regexp for an elisp command keybinding syntax, e.g. \\[some-command].
Regexp group 1 matches `some-command'.")

(defun match-next-keybinding (&optional limit)
  "Move point to the next expression matching  `elisp-symbol-keybinding-re'.
LIMIT is the maximum point to search to. Then, put properties on
the match that shows the key sequence. Non-bound commands are not
fontified."
  (when (and (re-search-forward
	      elisp-symbol-keybinding-re
	      limit t)
	     (fboundp (intern (match-string 1))))
    (let* ((beg (match-beginning 0))
	   (end (match-end 0))
	   (s (match-string 0))
	   (command (match-string 1))
	   (describe-func `(lambda ()
			     "Run `describe-function' on the command."
			     (interactive)
			     (describe-function (intern ,command))))
	   (find-func `(lambda ()
			 "Run `find-function' on the command."
			 (interactive)
			 (find-function (intern ,command))))
	   (map (make-sparse-keymap)))

      ;; this is what gets run when you click on it.
      (define-key map [mouse-1] describe-func)
      (define-key map [s-mouse-1] find-func)
      ;; Here we define the text properties
      (add-text-properties
       beg end
       `(local-map ,map
		   mouse-face highlight
		   help-echo ,(format
			       "%s\n\nClick for documentation.\ns-mouse-1 to find function."
			       (substitute-command-keys s))
		   keybinding t)))))

(defun command-or-variable (symbol)
  (cond
   ((fboundp symbol)
    'command)
   ((boundp sympol)
    'variable)
   (t
    'unknown)))


(defun match-next-emacs-command (&optional limit)
  "Move point to the next expression matching `this-syntax'.
LIMIT is the maximum point to look for a match. Then put a
tooltip on the match that shows the key sequence. Works on
commands and variables."
  (when (and (re-search-forward
	      "`\\([^']+\\)'"
	      limit t)
	     (or (boundp (intern (match-string 1)))
		 (fboundp (intern (match-string 1)))))
    (let* ((beg (match-beginning 0))
	   (end (match-end 0))
	   (s (match-string 0))
	   (command (match-string 1))
	   (description
	    (cond ((fboundp (intern command))
		   (documentation (intern command)))
		  ((boundp (intern command))
		   (describe-variable (intern command)))))
	   (describe-func
	    `(lambda ()
	       "Run `describe-function/variable' on the command."
	       (interactive)
	       (cond ((fboundp (intern ,command))
		      (describe-function (intern ,command)))
		     ((boundp (intern ,command))
		      (describe-variable (intern ,command))))))
	   (find-func `(lambda ()
			 "Run `find-function' on the command."
			 (interactive)
			 (find-function (intern ,command))))
	   (map (make-sparse-keymap)))

      ;; this is what gets run when you click on it.
      (define-key map [mouse-1] describe-func)
      (define-key map [s-mouse-1] find-func)
      ;; Here we define the text properties
      (add-text-properties
       beg end
       `(local-map ,map
		   mouse-face highlight
		   underline (when (eq 'variable (command-or-variable ,command)) t)
		   help-echo ,(format
			       "%s\n%s\nClick for documentation.%s"
			       (if (fboundp (intern command))
				   ;; function show key binding
				   (substitute-command-keys
				    (format "\\[%s]\n"
					    command))
				 "Variable")
			       description
			       (if (fboundp (intern command))
				   (format
				    "%s\ns-mouse-1 to find function." command)
				 ""))
		   keybinding t)))))


(define-minor-mode emacs-keybinding-command-tooltip-mode
  "Fontify on emacs keybinding syntax.
Adds a tooltip for keybinding, and make the command clickable to
get to the documentation."
  :lighter " KB"
  (if emacs-keybinding-command-tooltip-mode
      ;; turn them on
      (font-lock-add-keywords
       nil
       '((match-next-keybinding 1 font-lock-constant-face)
	 (match-next-emacs-command 1 font-lock-constant-face)))
    ;; turn them off
    (font-lock-remove-keywords
     nil
     '((match-next-keybinding 1 font-lock-constant-face)
       (match-next-emacs-command 1 font-lock-constant-face))))
  (font-lock-fontify-buffer))

(provide 'emacs-keybinding-command-tooltip-mode)

;;; emacs-keybinding-command-tooltip-mode.el ends here