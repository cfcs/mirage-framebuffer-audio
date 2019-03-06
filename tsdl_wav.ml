module Make_wav(Time : Mirage_time_lwt.S)(Sounds : Mirage_kv_lwt.RO) =
struct
  open Tsdl
  open Lwt.Infix

  let play sounds =
    (* http://wiki.libsdl.org/SDL_InitSubSystem *)
    ignore @@ Sdl.init_sub_system Sdl.Init.audio ; (* TODO *)

    let desired_audio_spec : Sdl.audio_spec =
      { Sdl.as_freq = 44100 ; (* 44100 Hz, as required by QubesOS *)
        (* AUDIO_S16LSB: http://wiki.libsdl.org/SDL_AudioFormat
           signed 16-bit samples in little-endian byte order*)
        as_format = Sdl.Audio.s16_lsb ;

        as_channels = 2 ; (* also required by QubesOS *)
        as_silence = 0 ; (* automatically populated *)
        (* "audio buffer size in samples (power of 2)": *)
        as_samples = 4096 ;
        as_size = 0_l ;  (* automatically populated *)
        as_callback = None;
      }
    in

    (* http://wiki.libsdl.org/SDL_OpenAudioDevice *)
    begin match Sdl.open_audio_device
      None (* SDL will pick sane default *)
      false (* is_capture *)
      desired_audio_spec
      0 (* Sdl.Audio.allow : don't allow changing anything *)
    with
    | Error (`Msg msg) -> failwith ("no audio for you: " ^ msg)
    | Ok (audio_device, audio_spec) ->
      assert (audio_spec.Sdl.as_samples = 4096) ;
      let rec play_wav audio_piece =
        if Sdl.get_queued_audio_size audio_device >= 82000 then begin
          (* 82000 is the freq (41000) times the sample_size (16bit)
             times the number of channels (2) divided by the time slot
             (0.5 seconds) and the amount of bits per byte (8).
             We try to keep 750ms of buffer around
          *)
          Sdl.pause_audio_device audio_device false ;
          Time.sleep_ns 250_000_000_L >>= fun () ->
          play_wav audio_piece
        end else
            Lwt.return_unit >>= fun () -> (* Lwt yield/breakpoint *)
            begin match Sdl.queue_audio audio_device
                          Cstruct.((of_string audio_piece).Cstruct.buffer) with
              | Ok () -> play_wav audio_piece
              | _ -> failwith "XX"
            end
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
end
