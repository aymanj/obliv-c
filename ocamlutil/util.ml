(** Utility functions for Coolaid *)
module E = Errormsg
open Pretty

exception GotSignal of int

let withTimeout (secs: float) (* Seconds for timeout *)
                (handler: int -> 'b) (* What to do if we have a timeout. The 
                                        * argument passed is the signal number 
                                        * received. *)
                (f: 'a -> 'b) (* The function to run *)
                (arg: 'a) (* And its argument *)
   : 'b = 
  let oldHandler = 
    Sys.signal Sys.sigalrm 
      (Sys.Signal_handle 
         (fun i -> 
           ignore (E.log "Got signal %d\n" i);
           raise (GotSignal i)))
  in
  let reset_sigalrm () = 
    ignore (Unix.setitimer Unix.ITIMER_REAL { Unix.it_value = 0.0;
                                              Unix.it_interval = 0.0;});
    Sys.set_signal Sys.sigalrm oldHandler;
  in
  ignore (Unix.setitimer Unix.ITIMER_REAL 
            { Unix.it_value    = secs;
              Unix.it_interval = 0.0;});
  (* ignore (Unix.alarm 2); *)
  try
    let res = f arg in 
    reset_sigalrm ();
    res
  with exc -> begin
    reset_sigalrm ();
    ignore (E.log "Got an exception\n");
    match exc with 
      GotSignal i -> 
        handler i
    | _ -> raise exc
  end

(** Print a hash table *)
let docHash (one: 'a -> 'b -> doc) () (h: ('a, 'b) Hashtbl.t) = 
  let theDoc = ref nil in
  (Hashtbl.fold 
     (fun key data acc -> acc ++ one key data)
     h
     align) ++ unalign
    


let anticompare a b = compare b a
;;

let rec list_span (p : 'a -> bool) (xs : 'a list) : 'a list * 'a list = 
  begin match xs with
  | [] -> ([],[])
  | x::xs' -> 
      if p x then
        let (ys,zs) = list_span p xs' in (x::ys,zs)
      else ([],xs)
  end
;;

let rec list_rev_append revxs ys =
  begin match revxs with
  | [] -> ys
  | x::xs -> list_rev_append xs (x::ys)
  end
;;
let list_insert_by (cmp : 'a -> 'a -> int) 
    (x : 'a) (xs : 'a list) : 'a list =
  let rec helper revhs ts =
    begin match ts with
    | [] -> List.rev (x::revhs)
    | t::ts' -> 
        if cmp x t >= 0 then helper (t::revhs) ts'
        else list_rev_append (x::revhs) ts
    end
  in
  helper [] xs
;;

let list_head_default (d : 'a) (xs : 'a list) : 'a =
  begin match xs with
  | [] -> d
  | x::_ -> x
  end
;;

let rec list_iter3 f xs ys zs =
  begin match xs, ys, zs with
  | [], [], [] -> ()
  | x::xs, y::ys, z::zs -> f x y z; list_iter3 f xs ys zs
  | _ -> invalid_arg "Util.list_iter3"
  end
;;
  
let rec get_some_option_list (xs : 'a option list) : 'a list =
  begin match xs with
  | [] -> []
  | None::xs  -> get_some_option_list xs
  | Some x::xs -> x :: get_some_option_list xs
  end
;;

let list_iteri (f: int -> 'a -> unit) (l: 'a list) : unit = 
  let rec loop (i: int) (l: 'a list) : unit = 
    match l with 
      [] -> ()
    | h :: t -> f i h; loop (i + 1) t
  in
  loop 0 l

let list_fold_lefti (f: 'acc -> int -> 'a -> 'acc) (start: 'acc) 
                   (l: 'a list) : 'acc = 
  let rec loop (i, acc) l = 
    match l with
      [] -> acc
    | h :: t -> loop (i + 1, f acc i h) t
  in
  loop (0, start) l

(** Generates the range of integers starting with a and ending with b *)
let rec int_range_list (a : int) (b :int) =
  if a > b then [] else
  a :: int_range_list (a+1) b
;;
