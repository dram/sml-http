signature HTTP = sig
    structure Method : HTTP_METHOD

    type Method = Method.Method

    type connection
    type request
    type response

    val openConnection : string * int -> connection
    val closeConnection : connection -> unit

    val newRequest : string -> request
    val setRequestBody : Word8Vector.vector -> request -> request
    val setRequestHeader : string * string -> request -> request
    val setRequestMethod : Method -> request-> request
    val setRequestUri : string -> request -> request

    val send : connection -> request -> unit
    val receive : connection -> response

    val getResponseBody : response -> Word8Vector.vector
end
