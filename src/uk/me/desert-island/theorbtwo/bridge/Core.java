package uk.me.desert_island.theorbtwo.bridge;

import java.io.PrintStream;
import java.io.IOException;
import java.lang.Class;
import java.util.HashMap;
import java.lang.reflect.Method;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Core {
  protected HashMap<String, Object> known_objects;
  protected PrintStream out_stream;

  public Core(PrintStream out) {
    this.known_objects = new HashMap<String, Object>();
    this.out_stream = out;
  }

  public void handle_line(StringBuilder in_line) {
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
        out_stream.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      try {
        obj = klass.newInstance();
        known_objects.put(obj_ident(obj), obj);
        out_stream.printf("%s %s\n", command_id, obj_ident(obj));
      } catch (java.lang.Throwable e) {
        out_stream.printf("%s thrown: %s", command_id, e.toString());
        return;
      }

    } else if (command_string.equals("DESTROY")) {
      known_objects.remove(split[2]);
      out_stream.printf("%s DESTROYed\n", command_id);
      
    } else if (command_string.equals("SHUTDOWN")) {
      System.err.printf("Got SHUTDOWN, shutting down.\n");
      
      if (!known_objects.isEmpty()) {
        for (String key : known_objects.keySet()) {
          out_stream.printf("Leaked %s: %s\n", key, known_objects.get(key));
        }
      }
      
      out_stream.printf("%s SHUTDOWN\n", command_id);
      
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
        meth = my_find_method(obj.getClass(), method_name, argument_classes);
      } catch (java.lang.Throwable e) {
        out_stream.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }
      
      try {
        ret = meth.invoke(obj, arguments);
      } catch (java.lang.Throwable e) {
        out_stream.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }
      
      out_stream.printf("%s call_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("call_static_method")) {
      Class<?> klass;
      Object ret;
      
      Class<?>[] argument_classes = new Class<?>[split.length - 4];
      Object[] arguments = new Object[split.length - 4];

      for (int i = 4; i < split.length; i++) {
        arguments[i-4] = known_objects.get(split[i]);
        argument_classes[i-4] = arguments[i-4].getClass();
      }

      try {
        klass = Class.forName(split[2]);
        ret = my_find_method(klass, split[3], argument_classes).invoke(null, arguments);
      } catch (java.lang.Throwable e) {
        out_stream.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      out_stream.printf("%s call_static_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("fetch_static_field")) {
      Class klass;
      Object ret;
      
      try {
        klass = Class.forName(split[2]);
        ret = klass.getField(split[3]).get(null);
      } catch (java.lang.Throwable e) {
        out_stream.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      out_stream.printf("%s call_static_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("fetch_field")) {
      Object obj;
      Object ret;
      
      //  0 1           2                                   3
      //  7 fetch_field [Ljava.lang.reflect.Method;>1b67f74 length
      try {
        obj = known_objects.get(split[2]);
        System.err.printf("fetch_field on %s for %s\n", obj.getClass().toString(), split[3]);
        System.err.printf("isArray? %s\n", obj.getClass().isArray());
        ret = obj.getClass().getField(split[3]).get(obj);
      } catch (java.lang.Throwable e) {
        e.printStackTrace();
        out_stream.printf("%s thrown: %s\n", command_id, e.toString());
        return;
      }

      out_stream.printf("%s call_static_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);
      
    } else if (command_string.equals("get_array_length")) {
      // fixme: why does fetch_field of an array not work?

      Object obj;
      obj = known_objects.get(split[2]);
      out_stream.printf("%s num return: %d\n", command_id, java.lang.reflect.Array.getLength(obj));

    } else if (command_string.equals("fetch_array_element")) {
      Object obj[];
      Integer index;
      Object ret;

      obj = (Object[]) known_objects.get(split[2]);
      index = Integer.decode(split[3]);
      ret = obj[index];

      out_stream.printf("%s call_static_method return: %s\n", command_id, obj_ident(ret));
      known_objects.put(obj_ident(ret), ret);


    } else if (command_string.equals("dump_string")) {
      Object obj = known_objects.get(split[2]);
      String out_string = (String)obj;
      Pattern backslash_pattern = Pattern.compile("\\\\");
      Pattern newline_pattern = Pattern.compile("\n");

      out_string = backslash_pattern.matcher(out_string).replaceAll("\\\\");
      out_string = newline_pattern.matcher(out_string).replaceAll("\\n");

      out_stream.printf("%s dump_string: '%s'\n", command_id, out_string);

    } else if (command_string.equals("make_string")) {
      String the_string = split[2];

      the_string = Pattern.compile("\\\\x20").matcher(the_string).replaceAll(" ");
      the_string = Pattern.compile("\\\\n").matcher(the_string).replaceAll("\n");
      the_string = Pattern.compile("\\\\\\\\").matcher(the_string).replaceAll("\\\\");

      known_objects.put(obj_ident(the_string), the_string);
      out_stream.printf("%s %s\n", command_id, obj_ident(the_string));

    } else {
      System.err.print("Huh?\n");
      System.err.printf("command_string: '%s'\n", command_string);
    }
  }

  private static Method my_find_method(Class<?> klass, String name, Class<?>[] args) 
    throws SecurityException, NoSuchMethodException
  {
    
    try {
      Method m;
      System.err.printf("Trying to find an obvious method for name=%s\n", name);
      m = klass.getMethod(name, args);
      System.err.printf("Still here after getMethod() call\n");
      return m;
    } catch (NoSuchMethodException e) {
      // Do nothing (just don't return).
    }

    System.err.printf("Trying non-obvious matches\n");
    // We do not have a perfect match; try for a match where the
    // method has primitive types but args has corresponding boxed types.
    for (Method m : klass.getMethods()) {
      boolean args_match = true;
      Class<?>[] m_args;

      if (!m.getName().equals(name)) {
        continue;
      }

      m_args = m.getParameterTypes();

      if (m_args.length != args.length) {
        continue;
      }

      System.err.printf("We have a strong canidate %s\n", m.toString());

      for (int i=0; i<args.length; i++) {
        
        String wanted_name = args[i].getName();
        String got_name = m_args[i].getName();

        // Java Language Specification, 3rd edition, 5.3 -- method arguments can have...
        // • an identity conversion (§5.1.1)
        if (args[i].equals(m_args[i])) {
          continue;
        }

        // • a widening primitive conversion (§5.1.2)
        // (Not applicable; our arguments will always be boxed types.)

        // • a widening reference conversion (§5.1.5)
        if (m_args[i].isAssignableFrom(args[i])) {
          System.err.printf("%s vs %s is OK (isAssignableFrom / a widening reference conversion\n",
                            wanted_name, got_name
                            );
          continue;
        }

        // • a boxing conversion (§5.1.7) optionally followed by widening reference conversion
        // • an unboxing conversion (§5.1.8) optionally followed by a widening primitive conversion.

        // Java Language Specification, 3rd edition, 5.1.8
        if (wanted_name.equals("java.lang.Boolean") && got_name.equals("boolean")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Byte") && got_name.equals("byte")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Character") && got_name.equals("char")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Short") && got_name.equals("short")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Integer") && got_name.equals("int")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Long") && got_name.equals("long")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Float") && got_name.equals("float")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Double") && got_name.equals("double")) {
          continue;
        }
        
        if (wanted_name.equals("java.lang.Integer") && got_name.equals("int")) {
          continue;
        }
        
        System.err.printf("Argument mismatch on wanted_name='%s' vs got_name='%s'\n", wanted_name, got_name);
        args_match = false;
        break;
      }

      if (args_match) {
        System.err.printf("We got it: %s\n", m.toString());
        return m;
      }
    }

    throw new NoSuchMethodException();
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