open Mirage

type sound_ty = Sound
let sound_typ = Type Sound

let switch_in ~target modname =
  let read_file fn =
    let {Unix.st_size; _} = Unix.stat fn in
    let buf = Bytes.create st_size in
    let fd = Unix.openfile fn Unix.[O_RDONLY] 0 in
    ignore @@ Unix.read fd buf 0 st_size ;
    Bytes.to_string buf
  in
  String.concat ""
  [ " () ) \n"; (* dirty hack to escape lazy () *)
    read_file ("s_" ^ (modname) ^ ".ml") ;
    "\n let " ^ modname ^ {|1 = lazy (
    let |} ;
    read_file (target ^ "_" ^ modname ^ ".ml") ;
    "\nin Lwt.return (module Make_"^modname^" : XXX_" ^ modname ^ "_S)"
  ]


let config_sound =
  impl @@ object inherit Mirage.base_configurable
    method module_name = "wav"
    method name = "wav"
    method ty = sound_typ
    method! packages : package list value =
      (Key.match_ Key.(value target) @@ begin function
          | `Xen | `Qubes ->
            [package "mirage-qubes" ;
             package "cstruct" ;
             package ~min:"3.0.0" "vchan"]
          | `Unix -> [package "tsdl"]
          | _ -> []
        end)
    method! connect mirage_info _modname _args =
      Key.eval (Info.context mirage_info) @@
      Key.match_ Key.(value target) @@ begin function
        | `Xen | `Qubes -> switch_in ~target:"qubes" "wav"
        | `Unix -> switch_in ~target:"tsdl" "wav"
        | _ -> switch_in ~target:"noop" "wav"
      end
  end

let main =
  let packages = [
    package "mirage-kv-lwt" ;
    package "mirage-time-lwt" ;
    package "rresult" ;
  ] in
  foreign
    ~deps:[abstract config_sound]
    ~packages
    "Unikernel.Main" (kv_ro @-> time @-> job)

let () =
  let sound_files : Mirage.kv_ro impl = Mirage.crunch "tracks" in
  register "qubes-skeleton" ~argv:no_argv [
    main $ sound_files $ default_time
  ]
