signature HTTP = sig
    type connection
    type method
    type request
    type response

    val MethodDelete : method
    val MethodGet : method
    val MethodPost : method
    val MethodPut : method

    val openConnection : string * int -> connection
    val closeConnection : connection -> unit

    val newRequest : string -> request
    val setRequestBody : Word8Vector.vector -> request -> request
    val setRequestHeader : string * string -> request -> request
    val setRequestMethod : method -> request-> request
    val setRequestUri : string -> request -> request

    val send : connection -> request -> unit
    val receive : connection -> response

    val getResponseBody : response -> Word8Vector.vector
end
