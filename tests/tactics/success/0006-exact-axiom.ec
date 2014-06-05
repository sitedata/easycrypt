(* -------------------------------------------------------------------- *)
type t.

pred p: t.

axiom Ap: forall x, p x.

(* -------------------------------------------------------------------- *)
lemma L: forall x, p x.
proof. exact Ap. qed.