module type XXX_wav_S =
  functor (Time : Mirage_time_lwt.S)  ->
  functor (Sounds : Mirage_kv_lwt.RO) ->
  sig
    val play : Sounds.t -> unit Lwt.t
  end
