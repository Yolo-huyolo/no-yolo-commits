#!/usr/bin/env sh

# --- Refuse pushes that land on a protected branch ---
# git feeds this hook one line per ref being pushed on stdin:
#   <local ref> <local sha1> <remote ref> <remote sha1>
# The auto-branch step in pre-commit only pauses a direct commit to main/master — it says nothing
# about what happens next. Fast-forward merge that branch locally and push, and the commit lands
# on the protected branch exactly as if pre-commit had never stepped in. This hook closes that gap
# by checking the actual destination of the push itself, independent of how the commit got there
# locally (direct commit that somehow slipped through, merge, rebase, whatever) — merged or not
# doesn't matter, only where it's headed.
#
# Deliberately blocks unconditionally rather than trying to special-case "but this one was already
# reviewed" — that judgment call is exactly what a human decides by reaching for --no-verify, not
# something a hook can infer from the ref list.
while read -r local_ref local_sha remote_ref remote_sha; do
  [ -z "$remote_ref" ] && continue
  remote_branch="${remote_ref#refs/heads/}"
  case " __PROTECTED__ " in
    *" $remote_branch "*)
      echo ""
      echo "⛔ Push to '$remote_branch' blocked."
      echo "   This repo doesn't push straight to a protected branch as a side effect of"
      echo "   merging or committing locally — that has to be a deliberate, visible step."
      echo ""
      echo "   Push your branch instead (git push origin \$(git branch --show-current)) and"
      echo "   open a PR, or if you really do mean to push here directly:"
      echo "   git push --no-verify"
      echo ""
      exit 1
      ;;
  esac
done

exit 0
