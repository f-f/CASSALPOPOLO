;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")
((tidal-mode
  ;; adapt if your `stack` binary is someplace else
  (tidal-interpreter . "~/.local/bin/stack")
  (tidal-interpreter-arguments . '("repl" "--ghci-options=-XOverloadedStrings")))
 )
