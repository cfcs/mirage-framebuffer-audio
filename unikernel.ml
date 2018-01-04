(* Copyright (C) 2016, Thomas Leonard
   See the README file for details. *)

open Lwt

let src = Logs.Src.create "unikernel" ~doc:"Main unikernel code"
module Log = (val Logs.src_log src : Logs.LOG)

module Main
    (Sounds_kv : Mirage_kv_lwt.RO)
    (Time : Mirage_time_lwt.S) = struct

  let start kv _time sounds =
    Time.sleep_ns 1_000_000_000L >>= fun () ->
    Log.app (fun f -> f "reading\n%!\n") ;
(*    Sounds.size sounds "tetris.wav" >>= (function
        | Ok size -> Lwt.return size ) >>= fun size ->
      Log.app (fun f -> f "tetris.wav: %Ld bytes" size);*)
    let module Sounds = (val (sounds) : S_wav.XXX_wav_S)(Time)(Sounds_kv) in
    Sounds.play kv >>= fun () ->
    Log.err (fun f -> f "...");
    Time.sleep_ns 10_000_000_000_L >|= fun () ->
    Log.err (fun f -> f "So long, and thanks for all the fish.")
end
