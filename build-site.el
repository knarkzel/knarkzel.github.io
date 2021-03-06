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

;; Install other dependencies
(use-package esxml
  :pin melpa-stable
  :ensure t)

(use-package htmlize
  :ensure t)

;; HTML template
(defun odd/org-html-template (contents info)
  (concat
   "<!DOCTYPE html>"
   (sxml-to-xml
    `(html (@ (lang "en"))
           (head
            (meta (@ (charset "utf-8")))
            (meta (@ (name "viewport")
                     (content "width=device-width, initial-scale=1, shrink-to-fit=no")))
            (link (@ (rel "stylesheet")
                     (href "/styles.css")))
            (title ,(concat (org-export-data (plist-get info :title) info) " - knarkzel.github.io")))
           (body 
            (div (@ (id "header"))
                 (h1 (@ (id "knarkzel")) "knarkzel.github.io")
                 (div (@ (id "nav"))
                      (a (@ (href "/")) "home")
                      (a (@ (href "/blog")) "blog")
                      (a (@ (href "/projects")) "projects")
                      (a (@ (href "/crustyahh")) "crustyahh")))
            (h1 ,(org-export-data (plist-get info :title) info))
            (div (@ (id "content")) ,contents))))))

;; Syntax highlight
(defvar highlight-path "highlight")

(defun highlight-org-html-code (code contents info)
  ;; Generating tmp file path.
  ;; Current date and time hash will ideally pass our needs.
  (setq temp-source-file (format "/tmp/highlight-%s.txt"(md5 (current-time-string))))
  ;; Writing block contents to the file.
  (with-temp-file temp-source-file (insert (org-element-property :value code)))
  ;; Executing the shell-command and reading output
  (shell-command-to-string (format "%s -i '%s' --syntax '%s' --out-format html --inline-css --fragment --stdout --enclose-pre -K 15 --force -J 1000 --style zenburn"
				                   highlight-path
                                   temp-source-file
				                   (or (org-element-property :language code)
				                       ""))))

(org-export-define-derived-backend 'pelican-html 'html
                                   :translate-alist '((template . odd/org-html-template)
                                                      (src-block .  highlight-org-html-code)
		                                              (example-block . highlight-org-html-code)))

(defun org-html-publish-to-html (plist filename pub-dir)
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
             :base-directory "./content"
             :publishing-function 'org-html-publish-to-html
             :publishing-directory "./public"
             :with-author nil           ;; Don't include author name
             :with-creator nil          ;; Include Emacs and Org versions in footer
             :with-toc nil              ;; Include a table of contents
             :with-drawers t
             :section-numbers nil       ;; Don't include section numbers
             :time-stamp-file nil)))    ;; Don't include time stamp in file

;; Customize the HTML output
(setq org-html-validation-link nil            ;; Don't show validation link
      org-html-head-include-scripts nil       ;; Use our own scripts
      org-html-head-include-default-style nil ;; Use our own styles
      org-html-html5-fancy nil
      org-html-doctype "html5"
      org-html-head "<title>knarkzel.github.io</title>
                     <link rel='stylesheet' href='/styles.css'/>
                     <link rel='icon' type='image/x-icon' href='/favicon.ico'>")

(defun odd/org-export-format-drawer (name content)
  (concat "<div class='drawer'>"
          "<p>" content "</p>"
          "</div>"))
(setq org-html-format-drawer-function 'odd/org-export-format-drawer)

;; Generate the site output
(org-publish-all t)

(message "Build complete!")
