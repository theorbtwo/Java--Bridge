package uk.me.desert_island.theorbtwo.bridge;

import android.widget.Toast;
import android.app.Service;
import android.content.Intent;
import java.net.*;
import uk.me.desert_island.theorbtwo.bridge.TcpIpConnection;

public class AndroidService extends Service {
  
  @Override
  public int onStartCommand(Intent intent, int flags, int startId) {
    InetAddress bind_address = InetAddress.getByName("0.0.0.0");
    ServerSocket server_socket = new ServerSocket(9849, 1, bind_address);
    
    /* FIXME: Where is the proper androidy place to put this mainloop? */
    while (true) {
      Socket connected_socket = server_socket.accept();
      
      new TcpIpConnection(connected_socket).start();
    }
    
    return START_STICKY;
  }
  
  @Override
  public android.os.IBinder onBind(Intent intent) {
    return null;
  }
}
