package uk.me.desert_island.theorbtwo.bridge;

import java.net.*;
import uk.me.desert_island.theorbtwo.bridge.TcpIpListener;
// FIXME: Try to get the android infection out of here?
import android.util.Log;


public class TcpIpListener extends Thread {
  private static final String LOG_TAG = "JavaBridge";

  @Override
  public void run()
  {
    
    ServerSocket server_socket;
    try {
      Log.e(LOG_TAG, "Warming up our ears...");
      server_socket = new ServerSocket(9849, 1);
    } catch (Exception e) {
      Log.wtf(LOG_TAG, "Creating listen socket", e);
      return;
    }
    
    Log.e(LOG_TAG, "Listening...");
    
    while (true) {
      try {
        Log.e(LOG_TAG, "who is that at the door?");
        Socket connected_socket = server_socket.accept();
        Log.e(LOG_TAG, "oooh, we've got a customer!");
        
        new TcpIpConnection(connected_socket).start();
      } catch (Exception e) {
        // I honestly don't know what would cause an error here.
        Log.wtf(LOG_TAG, "accept / start", e);
        return;
      }
    }
  }
}