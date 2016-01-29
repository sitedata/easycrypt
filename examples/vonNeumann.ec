(* --------------------------------------------------------------------
 * Copyright (c) - 2012--2016 - IMDEA Software Institute
 * Copyright (c) - 2012--2016 - Inria
 *
 * Distributed under the terms of the CeCILL-B-V1 license
 * -------------------------------------------------------------------- *)

(* -------------------------------------------------------------------- *)

(* In this theory, we illustrate some reasoning on distributions on
 * Von Neumann's trick to simulate a fair coin toss using only a
 * biased coin (of unknown bias). *)

require import Bool Pair Int IntExtra Real RealExtra List NewDistr.
require import StdRing StdOrder DBool Mu_mem.
(*---*) import MUniform RField RealOrder.

(* -------------------------------------------------------------------- *)
module Fair = {
  proc sample(): bool = {
    var b;

    b <$ {0,1};
    return b;
  }
}.

(* -------------------------------------------------------------------- *)
op p : { real | 0%r < p < 1%r } as in01_p.

clone import FixedBiased as Biased with op p <- p proof *.
realize in01_p by apply/in01_p.

module Simulate = {
  proc sample(): bool = {
    var b, b';

    b  <- true;
    b' <- true;
    while (b = b') {
      b  <$ dbiased;
      b' <$ dbiased;
    }
    return b;
  }
}.

(* -------------------------------------------------------------------- *)
op svn = [(true, false); (false, true)].
op dvn = duniform svn.

lemma vn1E a b : mu_x dvn (a, b) = (1%r / 2%r) * b2r (a <> b).
proof. by rewrite duniform1E; case: a b => [] [] @/svn. qed.

lemma vnE E : mu dvn E = 1%r/2%r * (count E svn)%r.
proof. by rewrite duniformE /= (_ : undup svn = svn). qed.

module SamplePair = {
  proc sample(): bool = {
    var b, b';

    (b, b') <$ dvn;
    return b;
  }
}.

equiv SamplePair: SamplePair.sample ~ Fair.sample: true ==> ={res}.
proof.
bypr (res{1}) (res{2})=> // &1 &2 b0.
have ->: Pr[Fair.sample() @ &2: b0 = res] = 1%r/2%r.
 byphoare (_: true ==> res = b0)=> //.
 by proc; rnd (pred1 b0); skip=> />; rewrite dboolb.
byphoare (_: true ==> res = b0)=> //.
proc; rnd ((pred1 b0) \o fst); skip => />.
rewrite vnE; pose c := count _ _; suff ->//: c%r = 1%r.
by move=> @/c; case: {+}b0.
qed.

(* -------------------------------------------------------------------- *)
(* We can now prove that sampling a pair in the restricted
   distribution and flipping two coins independently until
   they are distinct, returning the first one, are equivalent *)

lemma Simulate_is_Fair (x:bool) &m:
  Pr[Simulate.sample() @ &m: res = x] = Pr[Fair.sample() @ &m: res = x].
proof.
have <-:
    Pr[SamplePair.sample() @ &m: res = x]
  = Pr[Fair.sample() @ &m: res = x].
+ by byequiv SamplePair.
have ->:
    Pr[SamplePair.sample() @ &m: res = x]
  = mu dvn (pred1 x \o fst).
+ byphoare (_: true ==> res = x)=> //.
  by proc; rnd (pred1 x \o fst); skip=> />.
byphoare (_: true ==> res = x)=> //; proc; sp.
while true (b2i (b = b')) 1 (2%r * p * (1%r - p))=> />.
+ by move=> /#.
+ move=> ih; seq 2: true 1%r (mu dvn (pred1 x \o fst)) 0%r _ => //.
  by auto=> />; rewrite dbiased_ll.
+ by auto=> />; rewrite dbiased_ll.
split => //= [|z]; first by smt w=(in01_p).
conseq (_: true ==> b <> b'); first by move=> /#.
seq 1: b p (1%r - p) (1%r - p) p=> //;
  try by rnd; skip=> />; rewrite prbiasedE.
+ by rnd; skip=> /> _ -> />; rewrite prbiasedE.
by smt w=(in01_p).
qed.
