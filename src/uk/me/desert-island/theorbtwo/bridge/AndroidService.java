package uk.me.desert_island.theorbtwo.bridge;

import android.widget.Toast;
import android.app.Service;
import android.content.Intent;
import android.os.StrictMode;

public class AndroidService extends Service {
  private static final String LOG_TAG = "JavaBridge";

  @Override
  public int onStartCommand(Intent intent, int flags, int startId)
  {
    // For now, set the StrictMode policies to be fairly lenient, with
    // the intention of becomming less leniant later.
    // StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder()
    //                            .detectAll()
    //                            .penaltyLog()
    //                            .build());
    // StrictMode.setVmPolicy(new StrictMode.VmPolicy.Builder()
    //                        .detectAll()
    //                        .penaltyLog()
    //                        .build());

    (new TcpIpListener()).start();

    return START_STICKY;
  }
  
  @Override
  public android.os.IBinder onBind(Intent intent) {
    return null;
  }
}
