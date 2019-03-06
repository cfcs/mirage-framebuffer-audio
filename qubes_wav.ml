module Make_wav(Time : Mirage_time_lwt.S)(Sounds:Mirage_kv_lwt.RO) =
struct
  open Lwt.Infix
  let src = Logs.Src.create "pulseaudio" ~doc:"qubes-pulseaudio wav"
  module Log = (val Logs.src_log src : Logs.LOG)

  let play sounds =
    let module Pacat_framing : Qubes.Formats.FRAMING =
    struct
      let header_size = 0
      let body_size_from_header _ign = 1
    end
    in

    let module Pachan =  Qubes.Msg_chan.Make(Pacat_framing) in

    let qubes_pa_sink_vchan_port =  (* playback *)
      match Vchan.Port.of_string "4713" with
      | `Ok t -> t
      | _ -> failwith "hardcoded playback vchan port"
    and qubes_pa_source_vchan_port = (* mic input *)
      match Vchan.Port.of_string "4714" with
      | `Ok t -> t
      | _ -> failwith "hardcoded mic input vchan port"
    in
    let init () : Pachan.t Lwt.t =
      (*ignore the microphone, must be opened for Qubes to accept us: *)
      Lwt.async ( Pachan.server ~domid:0 ~port:qubes_pa_source_vchan_port );
      (* start playback server to let pacat-simple-vchan talk to us: *)
      Pachan.server ~domid:0 ~port:qubes_pa_sink_vchan_port () >>= fun server ->
      Log.app (fun f -> f "pulseaudio client connected%!") ;
      Lwt.return server
    in
    init () >>= fun pachan ->
    let play_wav wavfile =
      let rec loop foo =
          Pachan.send pachan [Cstruct.of_string foo] >|= fun _ -> ()
      in
      loop wavfile
    in
    let read_chunk name =
      Sounds.get sounds Mirage_kv.Key.(v name) >|=
      (function | Ok chunk -> chunk
                | _ -> failwith "ocaml-crunch oops")
    in
    let rec play_forever () =
      read_chunk "tetris01.wav" >>= play_wav >>= fun () ->
      read_chunk "tetris02.wav" >>= play_wav >>= fun () ->
      read_chunk "tetris03.wav" >>= play_wav >>= fun () ->
      read_chunk "tetris04.wav" >>= play_wav >>= fun () ->
      play_forever ()
    in play_forever ()
end
