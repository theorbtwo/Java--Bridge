package uk.me.desert_island.theorbtwo.bridge;

import java.io.PrintStream;
import java.io.IOException;
import java.lang.Class;
import java.util.HashMap;
import java.lang.reflect.Method;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Main {
  private static HashMap<String, Object> known_objects = new HashMap<String, Object>();

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

        handle_line(in_line, System.out, System.err);

        in_line = new StringBuilder();
      } else if (c == -1) {
        System.err.printf("Got -1 from read, shutting down.\n");

        if (!known_objects.isEmpty()) {
          for (String key : known_objects.keySet()) {
            System.err.printf("%s: %s\n", key, known_objects.get(key));
          }
        }
        
        System.exit(3);
      } else {
        in_line.appendCodePoint(c);
      }
    }
  }

  private static void handle_line(StringBuilder in_line, PrintStream out, PrintStream err) {
    String[] split = in_line.toString().split(" ");
    String command_id = split[0];
    String command_string = split[1];
    
    // err.printf("command_string = '%s', rest_string = '%s'\n", command_string, rest_string);
    
    if (command_string.equals("create")) {
      java.lang.Class klass;
      java.lang.Object obj;
      
      try {
        klass = Class.forName(split[2]);
      } catch (java.lang.Throwable e) {
        out.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      try {
        obj = klass.newInstance();
        known_objects.put(obj_ident(obj), obj);
        out.printf("%s %s\n", command_id, obj_ident(obj));
      } catch (java.lang.Throwable e) {
        out.printf("%s thrown: %s", command_id, e.toString());
        return;
      }

    } else if (command_string.equals("DESTROY")) {
      known_objects.remove(split[2]);
      out.printf("%s DESTROYed\n", command_id);
      
    } else if (command_string.equals("SHUTDOWN")) {
      err.printf("Got SHUTDOWN, shutting down.\n");
      
      if (!known_objects.isEmpty()) {
        for (String key : known_objects.keySet()) {
          out.printf("Leaked %s: %s\n", key, known_objects.get(key));
        }
      }
      
      out.printf("%s SHUTDOWN\n", command_id);
      
      System.exit(3);
      
    } else if (command_string.equals("call_method")) {
      String obj_ident   = split[2];
      String method_name = split[3];
      Object obj;
      Method meth;
      Object ret;
      
      Class<?>[] argument_classes = new Class<?>[split.length - 4];
      Object[] arguments = new Object[split.length - 4];

      // err.printf("call_method, obj_ident='%s', method_name='%s'\n", obj_ident, method_name);
      
      obj = known_objects.get(obj_ident);

      for (int i = 4; i < split.length; i++) {
        arguments[i-4] = known_objects.get(split[i]);
        argument_classes[i-4] = arguments[i-4].getClass();
      }

      try {
        meth = obj.getClass().getMethod(method_name, argument_classes);
      } catch (java.lang.Throwable e) {
        out.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }
      
      try {
        ret = meth.invoke(obj, arguments);
      } catch (java.lang.Throwable e) {
        out.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }
      
      out.printf("%s call_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("call_static_method")) {
      Class<?> klass;
      Object ret;
      
      try {
        klass = Class.forName(split[2]);
        ret = klass.getMethod(split[3]).invoke(null);
      } catch (java.lang.Throwable e) {
        out.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      out.printf("%s call_static_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("fetch_static_field")) {
      Class klass;
      Object ret;
      
      try {
        klass = Class.forName(split[2]);
        ret = klass.getField(split[3]).get(null);
      } catch (java.lang.Throwable e) {
        out.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      out.printf("%s call_static_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("dump_string")) {
      Object obj = known_objects.get(split[2]);
      String out_string = (String)obj;
      Pattern backslash_pattern = Pattern.compile("\\\\");
      Pattern newline_pattern = Pattern.compile("\n");

      out_string = backslash_pattern.matcher(out_string).replaceAll("\\\\");
      out_string = newline_pattern.matcher(out_string).replaceAll("\\n");

      out.printf("%s dump_string: '%s'\n", command_id, out_string);

    } else {
      err.print("Huh?\n");
      err.printf("command_string: '%s'\n", command_string);
    }
  }

  private static String obj_ident(java.lang.Object obj) {
    StringBuilder ret = new StringBuilder();
    if (obj == null) {
      return "null";
    }
    ret = ret.append(obj.getClass().getName());
    ret = ret.append(">");
    ret = ret.append(Integer.toHexString(System.identityHashCode(obj)));

    return ret.toString();
  }
}