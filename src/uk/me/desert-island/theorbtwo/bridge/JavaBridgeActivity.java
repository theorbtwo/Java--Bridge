package uk.me.desert_island.theorbtwo.bridge;

import android.app.Activity;
import android.os.Bundle;

import android.widget.Toast;
import android.content.Intent;

public class JavaBridgeActivity extends Activity {
  /** Called when the activity is first created. */
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.main);
  }
  
  @Override
  public void onStart() {
    super.onStart();
    Toast.makeText(this, "Starting JavaBridge service", Toast.LENGTH_SHORT).show();
    
    Intent runJB = new Intent(this, AndroidService.class);
    startService(runJB);
  }
}
