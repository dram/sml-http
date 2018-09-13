structure Http :> HTTP = struct

structure V = Word8Vector

type connection =
     (INetSock.inet, Socket.active Socket.stream) Socket.sock * string * int

datatype method = MethodDelete | MethodGet | MethodPost | MethodPut

type header = string * string
type request = string * method * string * header list * V.vector
type response = int * header list * V.vector

fun newRequest (host : string) : request =
    (host, MethodGet, "/", [], V.fromList [])

fun setRequestBody (body : V.vector) (request : request) : request =
    let
        val (host, method, uri, headers, _) = request
    in
        (host, method, uri, headers, body)
    end

fun setRequestHeader
        (name : string, value : string) (request : request) : request =
    let
        val (host, method, uri, headers, body) = request
    in
        (host, method, uri,
         (String.map Char.toLower name, value) :: headers,
         body)
    end

fun setRequestMethod (method : method) (request : request) : request =
    let
        val (host, _, uri, headers, body) = request
    in
        (host, method, uri, headers, body)
    end

fun setRequestUri (uri : string) (request : request) : request =
    let
        val (host, method, _, headers, body) = request
    in
        (host, method, uri, headers, body)
    end

fun getResponseBody (response : response) : V.vector =
    let
        val (_, _, body) = response
    in
        body
    end

fun openConnection (host : string, port : int) : connection =
    let
        val sock = INetSock.TCP.socket ()
    in
        case NetHostDB.getByName host of
            SOME hostEntry =>
            let
                val addr = INetSock.toAddr (NetHostDB.addr hostEntry, port)
            in
                Socket.connect (sock, addr)
              ; (sock, host, port)
            end
          | NONE => raise Fail ("Failed to get IP for host: " ^ host)
    end

fun send (connection : connection) (request : request) : unit =
    let
        val (host, method, uri, headers, body) = request
        val (sock, _, _) = connection
        val methodString = case method of
                               MethodDelete => "DELETE"
                             | MethodGet => "GET"
                             | MethodPost => "POST"
                             | MethodPut => "PUT"
        val requestLine = methodString ^ " " ^ uri ^ " HTTP/1.1"
        val headers' = List.foldl
                           (fn ((k, v), acc) =>
                               if List.exists
                                      (fn (k0, _) =>
                                          String.compare (k, k0) = EQUAL)
                                      acc
                               then
                                   acc
                               else
                                   (k, v) :: acc)
                           []
                           (List.concat [headers,
                                         if method = MethodPost
                                            orelse method = MethodPut then
                                             [("content-length",
                                               Int.toString (V.length body))]
                                         else
                                             [],
                                         [("user-agent", "SML-HTTP/0.1"),
                                          ("host", host)]])
    in
        Socket.sendVec (
            sock,
            (Word8VectorSlice.full
             o Byte.stringToBytes
             o String.concatWith "\r\n")
                ((requestLine :: List.map (fn (x, y) => x ^ ": " ^ y) headers')
                 @ ["\r\n"]))
      ; ignore (
            if V.length body <> 0 then
                Socket.sendVec (sock, Word8VectorSlice.full body)
            else
                0)
    end

fun receive (connection : connection) : response =
    let
        val blockSize = 4096
        val (sock, _, _) = connection

        fun readStatus (status, unparsed) =
            let
                val (left, right) = Substring.position "\r\n" unparsed
            in
                if Substring.isEmpty right then
                    readStatus (
                        status,
                        Substring.full
                            (Substring.string unparsed
                             ^ (Byte.bytesToString
                                o Socket.recvVec) (sock, blockSize)))
                else
                    case (Int.fromString
                          o Substring.string
                          o Substring.slice) (left, 9, SOME 3) of
                        SOME status => (status, Substring.triml 2 right)
                      | NONE => raise Fail (
                                   "Failed to parse status line: "
                                   ^ Substring.string left)
            end

        fun readHeaders (headers : header list,
                         contentLength : int,
                         unparsed : substring)
            : header list * int * substring =
            let
                val (left, right) = Substring.position "\r\n" unparsed
            in
                if Substring.isEmpty left then
                    (headers, contentLength, Substring.triml 2 right)
                else if Substring.isEmpty right then
                    readHeaders (
                        headers,
                        contentLength,
                        Substring.full
                            (Substring.string unparsed
                             ^ (Byte.bytesToString
                                o Socket.recvVec) (sock, blockSize)))
                else
                    let
                        val (name, value) = Substring.position ": " left
                        val name' = String.map Char.toLower
                                               (Substring.string name)
                        val contentLength' =
                            if String.compare (name', "content-length") = EQUAL
                            then
                                case (Int.fromString
                                      o Substring.string
                                      o Substring.slice) (value, 2, NONE) of
                                    SOME i => i
                                 | NONE => raise Fail (
                                              "Failed to parse Content-Length"
                                              ^ " header value: "
                                              ^ Substring.string value)
                            else
                                contentLength
                    in
                        readHeaders
                            ((name',
                              (Substring.string
                               o Substring.slice)
                                  (value, 2, NONE)) :: headers,
                             contentLength',
                             Substring.triml 2 right)
                    end
            end

        fun readBody (contents, length) =
            if length <= 0 then
                contents
            else
                let
                    val content = Socket.recvVec (sock, length)
                in
                    readBody (content :: contents, length - V.length content)
                end

        val (status, unparsed) = readStatus ("", Substring.full "")
        val (headers, contentLength, unparsed') = readHeaders ([], 0, unparsed)
    in
        (status, headers, (V.concat o List.rev o readBody) (
                              [Byte.stringToBytes
                                   (Substring.string unparsed')],
                              contentLength - Substring.size unparsed'))
    end

fun closeConnection (connection : connection) : unit =
    let
        val (sock, _, _) = connection
    in
        Socket.close sock
    end

end
