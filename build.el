;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("melpa-stable" . "https://stable.melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)

;; Load the publishing system
(require 'org)
(require 'ox)
(require 'ox-html)
(require 'ox-publish)

(use-package esxml
  :pin melpa-stable
  :ensure t)

(use-package htmlize
  :ensure t)

(use-package rainbow-delimiters
  :ensure t
  :init
  (add-hook 'prog-mode-hook 'rainbow-delimiters-mode))

;; Extra languages
(use-package zig-mode
  :ensure t)

;; Theme
(use-package doom-themes
  :ensure t
  :init
  (load-theme 'doom-flatwhite t))

;; HTML template
(defun html-template (contents info)
  (concat
   "<!DOCTYPE html>"
   (sxml-to-xml
    `(html (@ (lang "en"))
      (head
       (meta (@ (charset "UTF-8")))
       (title ,(org-export-data (plist-get info :title) info))
       (link (@ (rel "stylesheet") (href "/styles.css"))))
      (body
        (table
         (@ (width "100%") (cellpadding "0") (cellspacing "0") (border "0"))
         (td
          (@ (align "left"))
          (b ,(org-export-data (plist-get info :title) info))
          ,(unless (equal (org-export-data (plist-get info :title) info) "knarkzel.srht.site")
             " | <a href=../>Go back</a>"))
         (td (@ (align "right"))
          "Written by "
          (a (@ (href "https://git.sr.ht/~knarkzel")) "~knarkzel")))
         (hr)
         (main ,contents))))))

(org-export-define-derived-backend 'pelican-html 'html :translate-alist '((template . html-template)))

(defun publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML, using the FILENAME as the output directory."
  (org-publish-org-to 'pelican-html filename
		              (concat (when (> (length org-html-extension) 0) ".")
			                  (or (plist-get plist :html-extension)
				                  org-html-extension
				                  "html"))
		              plist pub-dir))

;; Define the publishing project
(setq org-publish-project-alist
      (list
       (list "org-site:main"
             :recursive t
             :base-directory "./src"
             :publishing-function 'publish-to-html
             :publishing-directory "./public"
             :with-author nil
             :with-creator nil
             :with-toc nil
             :with-drawers nil
             :section-numbers nil
             :time-stamp-file nil)))

;; Customize the HTML output
(setq org-html-validation-link t
      org-html-head-include-scripts nil
      org-html-head-include-default-style nil
      org-html-html5-fancy nil
      org-html-doctype "html5"
      org-html-htmlize-output-type 'css)

(setq-default tab-width 4)

;; Generate the site output
(org-publish-all t)
