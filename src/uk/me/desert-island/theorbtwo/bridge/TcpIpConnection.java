package uk.me.desert_island.theorbtwo.bridge;

/* Should try to avoid android stuff leaking into here! */
import java.net.*;
import java.io.*;
import uk.me.desert_island.theorbtwo.bridge.Core;

public class TcpIpConnection extends java.lang.Thread {
  public Socket connected_socket;

  public TcpIpConnection(Socket connected_socket_arg) {
    connected_socket = connected_socket_arg;
  }

  @Override
  public void run() {
    InputStream in_stream; 
    try {
      in_stream = connected_socket.getInputStream();
    } catch (IOException e) {
      return;
    }
    PrintStream out_stream;
    try {
      out_stream = new PrintStream(connected_socket.getOutputStream(), true, "UTF-8");
    } catch (IOException e) {
      // UnsupportedEncodingException is a subclass of IOException.
      return;
    }
    

    // FIXME: Hm.  Everything else looks like it might just be a copy of StdInOut... should it be merged back in?
    
    out_stream.println("Ready");
    
    
    java.lang.StringBuilder in_line = new StringBuilder();
    while (true) {
      int c;
      
      try {
        c = in_stream.read();
      } catch (java.io.IOException e) {
        System.err.println("IOException!");
        return;
      }

      if (c == 10) {
        // newline.
        //System.err.printf("Got a line: '%s'\n", in_line);

        Core.handle_line(in_line, out_stream, System.err);

        in_line = new StringBuilder();
      } else if (c == 13) {
        // CR, \cM
        // Ignore it.
      } else if (c == -1) {
        System.err.printf("Got -1 from read, shutting down.\n");
        
        return;
      } else {
        in_line.appendCodePoint(c);
      }
    }

  }
}