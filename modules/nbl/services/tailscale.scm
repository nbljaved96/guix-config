(define-module (nbl services tailscale)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services configuration)
  #:use-module (guix records)
  #:use-module (guix gexp)
  #:use-module (ice-9 match)
  #:use-module (nbl packages tailscale)
  #:use-module (gnu packages linux)
  #:export (tailscaled-service-type tailscaled-configuration))

(define-record-type* <tailscaled-configuration>
  tailscaled-configuration make-tailscaled-configuration
  tailscaled-configuration?
  (tailscale tailscaled-configuration-tailscale
             (default tailscaled))
  (state-file tailscaled-configuration-state-file
              (default "/var/lib/tailscale/tailscaled.state"))
  (extra-args tailscaled-configuration-extra-args
              (default '())))

(define (tailscaled-shepherd-service config)
  (let ((tailscale (tailscaled-configuration-tailscale config))
        (state-file (tailscaled-configuration-state-file config))
        (extra-args (tailscaled-configuration-extra-args config)))
    (list
     (shepherd-service
      (provision '(tailscaled))
      (requirement '(user-processes))
      (start #~(make-forkexec-constructor
                (list #$(file-append tailscale "/bin/tailscaled")
                      "-state" #$state-file
                      #+@extra-args)
                #:environment-variables
                (list (string-append "PATH=" #$iptables "/sbin:" #$iptables "/bin"))
                #:log-file "/var/log/tailscaled.log"))
      (stop #~(make-kill-destructor))))))

(define tailscaled-service-type
  (service-type
   (name 'tailscaled)
   (extensions
    (list (service-extension shepherd-root-service-type
                             tailscaled-shepherd-service)))
   (default-value (tailscaled-configuration))
   (description "Run the Tailscale daemon.")))
