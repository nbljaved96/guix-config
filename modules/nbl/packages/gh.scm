(define-module (nbl packages gh)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix licenses))

(define-public gh
  (package
   (name "gh")
   (version "2.76.1")
   (source
    (origin
     (method url-fetch/tarbomb)
     (uri (string-append "https://github.com/cli/cli/releases/download/v" version
                         "/gh_" version "_linux_amd64.tar.gz"))
     (sha256
      (base32 "1s9nc2q0p0fhafz9nc5gnqc2hk1sqlc6mflgwfd8hqj4ifipqdhq"))))
   (build-system copy-build-system)
   (arguments
    (list
     #:validate-runpath? #t
     #:phases
     #~(modify-phases
        %standard-phases
        (add-after 'unpack 'change-directory
                   (lambda _
                     (chdir #$(string-append "gh_" version "_linux_amd64")))))))
   (supported-systems '("x86_64-linux"))
   (synopsis "GitHub’s official command line tool")
   (description
    "gh is GitHub on the command line. It brings pull requests, issues, and other GitHub concepts to the terminal next to where you are already working with git and your code.")
   (home-page "https://cli.github.com/")
   (license expat)))

gh
