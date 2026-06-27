(define-module (nbl packages custom-emacs)
  #:use-module (guix packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages xorg))

(define-public nbl-emacs
  (package
   (inherit emacs)
   (name "nbl-emacs")
   (inputs (modify-inputs (package-inputs emacs)
                          (prepend libxaw)))))

nbl-emacs
