---
layout: post
keywords: [tshark, wireshark, flow, network]
categories: [pdml2flow, networking]
---

`pdml2flow` version 5.0 was released. New key features are:

* Plugin interface version 2: cli integration
* Replaced `pdml2xml` and `pdml2json` with `pdml2frame`
* 98% test coverage
* Python 3.6 support

Upgrade using `pip` is as simple as:

```bash
$ sudo pip install --upgrade pdml2flow
```

# Plugin interface version 2

Before 5.0 plugins were configure with environment variables. Now, plugins are loaded and configured from the command line. In order to support multiple output sink all the flow writing logic was moved into plugin as well. Using `pdml2flow` with the JSON output plugin:
```
$ pdml2flow +json '-h'
```

The argument after the plugin invocation is passed straight to the plugin. Which means that `-h` from the example above, is passed to the JSON plugin. To support this the plugin interface was changed. Now `__init__` will be passed all arguments from the command line. In this case `[ '-h' ]`.

```diff
diff --git a/pdml2flow/plugin.py b/pdml2flow/plugin.py
index db016a3..06f7425 100644
--- a/pdml2flow/plugin.py
+++ b/pdml2flow/plugin.py
@@ -1,7 +1,20 @@
 # vim: set fenc=utf8 ts=4 sw=4 et :
 
-class Plugin1(object):
-    """Version 1 plugin interface."""
+class Plugin2(object): # pragma: no cover
+    """Version 2 plugin interface."""
+
+    @staticmethod
+    def help():
+        """Return a help string."""
+        pass
+
+    def __init__(self, *args):
+        """Called once during startup."""
+        pass
+
+    def __deinit__(self):
+        """Called once during shutdown."""
+        pass
 
     def flow_new(self, flow, frame):
         """Called every time a new flow is opened."""
```

This change alone is not the reason for the interface bump. The true interface break comes from the change in the `flow` class. Before 5.0 frames of the flow were accessible using a getter called `get_frames()`. This was replaced with a more pythonic getter `frames`. Example usage:

```python
flow.frames['frame']['time_relative']['raw']
```

or as an alternative using a list:

```python
flow.frames[['frame', 'time_relative', 'raw']]
```

# Replaced `pdml2xml` and `pdml2json` with `pdml2frame`

Since all the output was moved into plugins, `pdml2xml` and `pdml2json` no longer made sense. This is why I replaced those tools with `pml2frame` which supports the same plugin interface as `pdml2flow`. This means `pdml2xml` becomes `pml2frame +xml`. And for `pdml2json` use `pdml2frame +json` instead.

