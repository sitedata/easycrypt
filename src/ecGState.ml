(* --------------------------------------------------------------------
 * Copyright (c) - 2012-2014 - IMDEA Software Institute and INRIA
 * Distributed under the terms of the CeCILL-C license
 * -------------------------------------------------------------------- *)

(* -------------------------------------------------------------------- *)
open EcMaps

(* -------------------------------------------------------------------- *)
type nid_t    = EcUid.uid
type loglevel = [`Debug | `Info | `Warning]

type notifier = {
  nt_id : nid_t;
  nt_cb : loglevel -> string Lazy.t -> unit;
}

type gstate = {
  mutable gs_flags     : bool Mstr.t;
  mutable gs_notifiers : notifier list;
  mutable gs_loglevel  : loglevel;
}

(* -------------------------------------------------------------------- *)
let create () : gstate =
  { gs_flags     = Mstr.empty;
    gs_notifiers = [];
    gs_loglevel  = `Info; }

(* -------------------------------------------------------------------- *)
let copy (gs : gstate) : gstate =
  { gs_flags     = gs.gs_flags    ;
    gs_notifiers = gs.gs_notifiers;
    gs_loglevel  = gs.gs_loglevel ; }

(* -------------------------------------------------------------------- *)
let from_flags (flags : (string * bool) list) : gstate =
  let gstate = create () in
  { gstate with gs_flags = Mstr.of_list flags; }

(* -------------------------------------------------------------------- *)
let getflag ?(default = false) (name : string) (g : gstate) =
  Mstr.find_def default name g.gs_flags

(* -------------------------------------------------------------------- *)
let setflag (name : string) (value : bool) (g : gstate) =
  g.gs_flags <- Mstr.add name value g.gs_flags

(* -------------------------------------------------------------------- *)
let add_notifier (notifier : loglevel -> string Lazy.t -> unit) (gs : gstate) =
  let notifier = { nt_id = EcUid.unique (); nt_cb = notifier; } in
  gs.gs_notifiers <- notifier :: gs.gs_notifiers; notifier.nt_id

(* -------------------------------------------------------------------- *)
let rem_notifier (nid : nid_t) (gs : gstate) =
  gs.gs_notifiers <- List.filter (fun nt -> nt.nt_id = nid) gs.gs_notifiers

(* -------------------------------------------------------------------- *)
let loglevel (gs : gstate) =
  gs.gs_loglevel

(* -------------------------------------------------------------------- *)
let set_loglevel (lvl : loglevel) (gs : gstate) =
  gs.gs_loglevel <- lvl

(* -------------------------------------------------------------------- *)
let accept_log ~level ~wanted =
  match level, wanted with
  | `Debug  , (`Debug | `Info | `Warning) -> true
  | `Info   , (         `Info | `Warning) -> true
  | `Warning, (                 `Warning) -> true
  | _       , _                           -> false

(* -------------------------------------------------------------------- *)
let string_of_loglevel = function
  | `Debug   -> "debug"
  | `Info    -> "info"
  | `Warning -> "warning"

(* -------------------------------------------------------------------- *)
let notify (lvl : loglevel) (msg : string Lazy.t) (gs : gstate) =
  let do1 (notifier : notifier) =
    try  notifier.nt_cb lvl msg
    with _ -> ()
  in

  if accept_log ~level:gs.gs_loglevel ~wanted:lvl then
    List.iter do1 gs.gs_notifiers