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

        handle_line(in_line);

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

  private static void handle_line(StringBuilder in_line) {
	String command_string;
	String rest_string;
	  
	command_string = in_line.substring(0, in_line.indexOf(" "));
	rest_string = in_line.substring(in_line.indexOf(" ")+1);
	
	System.err.printf("command_string = '%s', rest_string = '%s'\n", command_string, rest_string);
	  
	if (command_string.equals("create")) {
      java.lang.Class klass;
      java.lang.Object obj;
      
      try {
        klass = Class.forName(rest_string);
      } catch (java.lang.Throwable e) {
        System.out.printf("thrown: %s\n", e.toString());
        return;
      }

      try {
        obj = klass.newInstance();
        known_objects.put(obj_ident(obj), obj);
        System.out.printf("%s\n", obj_ident(obj));
      } catch (java.lang.Throwable e) {
        System.out.print("thrown: " + e.toString());
        return;
      }

    } else if (command_string.equals("DESTROY")) {
      known_objects.remove(rest_string);
      System.out.printf("DESTROYed\n");
      
    } else if (command_string.equals("SHUTDOWN")) {
        System.err.printf("Got SHUTDOWN, shutting down.\n");

        if (!known_objects.isEmpty()) {
          for (String key : known_objects.keySet()) {
            System.err.printf("%s: %s\n", key, known_objects.get(key));
          }
        }
        
        System.out.printf("SHUTDOWN\n");

        System.exit(3);

    } else if (command_string.equals("call_method")) {
      String obj_ident;
      String method_name;
      Object obj;
      Method meth;
      Object ret;
      
      obj_ident = rest_string.substring(0, rest_string.indexOf(" "));
      rest_string = rest_string.substring(rest_string.indexOf(" ")+1);
      
      if (rest_string.indexOf(" ") > -1) {
        System.err.printf("junk after method name, rest_string='%s'\n", rest_string);
        return;
      }

      method_name = rest_string;
      rest_string = "";

      System.err.printf("call_method, obj_ident='%s', method_name='%s', rest_string='%s'\n", obj_ident, method_name, rest_string);

      obj = known_objects.get(obj_ident);
      try {
        meth = obj.getClass().getMethod(method_name);
      } catch (java.lang.Throwable e) {
        System.out.printf("thrown: %s\n", e.toString());
        return;
      }

      try {
        ret = meth.invoke(obj);
      } catch (java.lang.Throwable e) {
        System.out.printf("thrown: %s\n", e.toString());
        return;
      }
      
      System.out.printf("call_method return: %s\n", obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);

    } else if (command_string.equals("call_static_method")) {
      String[] split = rest_string.split(" ");
      Class klass;
      Object ret;

      if (split.length != 2) {
        System.err.printf("Syntax error in call_static_method, split into %d pieces", split.length);
      }

      try {
        klass = Class.forName(split[0]);
        ret = klass.getMethod(split[1]).invoke(null);
      } catch (java.lang.Throwable e) {
        System.out.printf("thrown: %s\n", e.toString());
        return;
      }

      System.out.printf("call_static_method return: %s\n", obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("dump_string")) {
      Object obj = known_objects.get(rest_string);
      String out_string = (String)obj;
      Pattern backslash_pattern = Pattern.compile("\\\\");
      Pattern newline_pattern = Pattern.compile("\n");

      out_string = backslash_pattern.matcher(out_string).replaceAll("\\\\");
      out_string = newline_pattern.matcher(out_string).replaceAll("\\n");

      System.out.printf("dump_string: '%s'\n", out_string);

    } else {
      System.err.print("Huh?\n");
      System.err.printf("command_string: '%s'\n", command_string);
    }
  }

  private static String obj_ident(java.lang.Object obj) {
    StringBuilder ret = new StringBuilder();
    ret = ret.append(obj.getClass().getName());
    ret = ret.append(">");
    ret = ret.append(Integer.toHexString(obj.hashCode()));

    return ret.toString();
  }
}