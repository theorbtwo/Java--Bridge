package uk.me.desert_island.theorbtwo.bridge;

import uk.me.desert_island.theorbtwo.bridge.Core;

public class StdInOut {
  public static void main(String[] args)
    throws java.io.IOException
  {
    System.out.println("Ready\n");

    java.lang.StringBuilder in_line = new StringBuilder();
    while (true) {
      int c;

      try {
        c = System.in.read();
      } catch (java.io.IOException e) {
        System.err.println("IOException!");
        System.exit(1);
        // usless, but keeps javac from giving a might-be-used-uninit error
        c = -1;
      }

      if (c == 10) {
        // newline.
        //System.err.printf("Got a line: '%s'\n", in_line);

        Core.handle_line(in_line, System.out, System.err);

        in_line = new StringBuilder();
      } else if (c == -1) {
        System.err.printf("Got -1 from read, shutting down.\n");
        
        System.exit(3);
      } else {
        in_line.appendCodePoint(c);
      }
    }
  }

}