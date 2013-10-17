require import Map.
require import Distr.
require import RandOrcl.

module ROe = {

  var xs : from
  var hs : to
  var m : (from, to) map

  fun init (x:from) : unit = {
    xs = x;
    m = empty;
    hs = $dsample;

  }

  fun o(x:from) : to = {
    var y : to;
    y = $dsample;
    if (!in_dom x m) 
      m.[x] = if x = xs then hs else y;
    return proj (m.[x]);
  }
     
}.

module type Adv (O:ARO) = {
  fun a0 () : from {}
  fun a1 () : bool 
}.

section.

 declare module A : Adv {ROM.RO, ROe}.

 local module A1 = A(ROM.RO).
 local module A2 = A(ROe). 
 
 local module G1 = {
  fun main() : bool = {
    var x:from;
    var b:bool;
    x = A1.a0();
    ROM.RO.init();
    b = A1.a1();
    return b;
  }
 }.

 local module G2 = {
  fun main() : bool = {
    var x:from;
    var b:bool;
    x = A2.a0();
    ROe.init(x);
    b = A2.a1();
    return b;
  }
}.

 local lemma foo1 : 
  weight dsample = 1%r => 
  equiv [G2.main ~ G1.main : ={glob A} ==>
                            ={glob A,res} /\ ROe.m{1} = ROM.RO.m{2} ].
 proof.
  intros Hw;fun.
  inline ROM.RO.init ROe.init.
  seq 4 2 : (={glob A,x} /\ ROe.m{1} = ROM.RO.m{2} );first by eqobs_in. 
  eager (h : ROe.hs = $dsample;  ~  : true ==> true) : (={glob A} /\ ROe.m{1} = ROM.RO.m{2}).
  rnd{1} => //.
  trivial.
  eager fun h (ROe.m{1} = ROM.RO.m{2}) => //.
  eager fun.
  case (!in_dom x ROe.m){1}.
   rcondt{1} 3.
     intros &m;conseq * (_ : _ ==> true) => //.
   rcondt{2} 2.
     intros &m;conseq * (_ : _ ==> true) => //.
   wp;case (x=ROe.xs){1}.
    rnd{1};rnd => //.
    rnd;rnd{1};skip;progress => //;smt.
  rcondf{1} 3.
    intros &m;conseq * (_ : _ ==> true) => //.
  rcondf{2} 2.
    intros &m;conseq * (_ : _ ==> true) => //.
  eqobs_in;rnd{1} => //.
  fun;eqobs_in.
save.
