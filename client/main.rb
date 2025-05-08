require "socket"

require_relative "./GameWindow.rb"

def connect_server(tcp_server_ipv4, tcp_server_port)
    ret_select_or_nil = nil
    sockaddr_server = Socket.sockaddr_in(tcp_server_port, tcp_server_ipv4)
    tcp_server_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    linger = [1, 0].pack('ii')
    tcp_server_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, linger)
    tcp_server_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
    
    begin
        tcp_server_socket.connect_nonblock(sockaddr_server)
    #rescue Errno::ENETDOWN => e # the network is down
    #rescue Errno::EADDRINUSE => e # the socket"s local address is already in use
    #rescue Errno::EINTR => e # the socket was cancelled
    rescue IO::WaitWritable => e
        ret_select_or_nil = IO.select(nil, [tcp_server_socket], nil, 5)
    rescue Errno::EALREADY => e # see Errno::EINVAL
        puts("connecting ...")
    #rescue Errno::EADDRNOTAVAIL => e # the remote address is not a valid address, such as ADDR_ANY TODO check ADDRANY TO INADDR_ANY
    #rescue Errno::EAFNOSUPPORT => e # addresses in the specified family cannot be used with with this socket
    rescue Errno::ECONNREFUSED => e # the target sockaddr was not listening for connections refused the connection request
        puts(e.inspect << "\n\n" << e.backtrace.join("\n"))
    #rescue Errno::EFAULT => e # the socket"s internal address or address length parameter is too small or is not a valid part of the user space address
    #rescue Errno::EINVAL => e # the socket is a listening socket
    rescue Errno::EISCONN => e # the socket is already connected
        puts("success")
    #rescue Errno::ENETUNREACH => e # the network cannot be reached from this host at this time
    #rescue Errno::EHOSTUNREACH => e # no route to the network is present
    #rescue Errno::ENOBUFS => e # no buffer space is available
    #rescue Errno::ENOTSOCK => e # the socket argument does not refer to a socket
    #rescue Errno::ETIMEDOUT => e # the attempt to connect timed out before a connection was made.
    #rescue Errno::EWOULDBLOCK => e # the socket is marked as nonblocking and the connection cannot be completed immediately
    #rescue Errno::EACCES => e # the attempt to connect the datagram socket to the broadcast address failed
    end

    return false if ret_select_or_nil.nil?

    $count = 0
    $buffer = String.new("", capacity: 4096)
    
    loop do
        begin
            str = "hello client #{$count}"
            data = [str.bytesize, $count]
            packedData = data.pack("SS") << str
            tcp_server_socket.write_nonblock(packedData)
            print("str length: #{str.length}, packedData length: #{packedData.length}\n")
        rescue IO::WaitReadable => e # the socket is marked as nonblocking and the connection cannot be completed immediately
            puts("WaitReadable (write_nonblock)")
        rescue Errno::ECONNRESET => e
            puts(e.inspect)
            break
        end

        '''
        begin
            tcp_server_socket.read_nonblock(4096, $buffer)
            puts($buffer)
        rescue IO::WaitReadable => e # the socket is marked as nonblocking and the connection cannot be completed immediately
            puts("WaitReadable (read_nonblock)")
        end
        '''
    
        sleep(1)
        $count = ($count + 1) % 65535
    end
    
    tcp_server_socket.close

    return true
end

$game_window = GameWindow.new()
$game_window.show