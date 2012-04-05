(*
 * Copyright (C) Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

(** A byte-level transport over the xenstore Unix domain socket *)

open Lwt

let xenstored_socket = "/var/run/xenstored/socket"

module Client = struct

  type t = Lwt_unix.file_descr
  let create () =
    let sockaddr = Lwt_unix.ADDR_UNIX(xenstored_socket) in
    let fd = Lwt_unix.socket Lwt_unix.PF_UNIX Lwt_unix.SOCK_STREAM 0 in
    lwt () = Lwt_unix.connect fd sockaddr in
  return fd
  let destroy fd = Lwt_unix.close fd
  let read = Lwt_unix.read
  let write = Lwt_unix.write

end

module Server = struct

  type t = Lwt_unix.file_descr
  let create () =
    let sockaddr = Lwt_unix.ADDR_UNIX(xenstored_socket) in
    let fd = Lwt_unix.socket Lwt_unix.PF_UNIX Lwt_unix.SOCK_STREAM 0 in
    Lwt_unix.bind fd sockaddr;
    Lwt_unix.listen fd 5;
    fd

  let rec serve process fd =
    lwt conns, _(*exn_option*) = Lwt_unix.accept_n fd 16 in
    List.iter process conns;
    serve process fd

end

