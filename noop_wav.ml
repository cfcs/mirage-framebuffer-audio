module Make_wav (Sounds : Mirage_kv_lwt.RO) =
struct
  let play (_ : Sounds.t) = Lwt.return_unit
end
