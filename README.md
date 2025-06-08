# Warning!

As of writing this README, there has been zero testing. That will change in the next few days. Also, the windows bindings haven't been generated, and the generation might fail. Once I bother to setup Jai on windows I'll fix it eventually.

# What's better about this fork?

- Basically, the previous method of providing the actual functions is limited. On linux for example, many functions provided by extensions weren't available ([more info](#The problem)).
- Updated headers to 1.4.313.

# Usage

### Generating
run:
```sh
jai generate.jai
```

If it worked it should print a gazillion stripped functions and then at the end it should report zero functions along with more sensible numbers for the structs etc.
The bindings only have the function types, because we don't link them with the usual `#foreign` .
### Using the bindings
Just import the module as usual.

The functions need some more setup. I encourage you to read [why it works like this](#Details on the functions), but here is the usual way to do it:
1. You must provide the function pointer for `vkGetInstanceProcAddr`. If you use a platform abstraction layer like SDL, there will be a function that gives you exactly that. You can also use something like dlopen and dlsym (or the equivalents for your target platforms) to get this function pointer.
2. call `load_proc_addresses` with the function pointer as the argument. Now you can call a small set of functions related to instance creation.
3. After creating the instance, you can call `load_proc_addresses` with the instance as argument. Now you can call any function (taking into account which extensions you have enabled of course).
4. After creating the device, you can call `load_proc_addresses` yet again with the device as argument (WARNING: only do this if you only ever use this same `VkDevice` in your entire program OR you know what you are doing).

Step 4 is optional but can be slightly more performant.

@Todo: make an example

# Details on the functions

As always when working with Vulkan, we can consult the spec (specifically section 4.1). The following assumes knowledge of the specific portion of the spec on this topic.
### The problem
Vulkan drivers come with a loader. This loader may expose some set of core functions that may be linked against, but only one is really required: `vkGetInstanceProcAddr`. 
The previous bindings generator linked against this driver-provided loader on linux, which meant that many functions didn't make it into the bindings. On windows it linked against a separately provided library, which again may or may not expose all of the functions with the correct names.
The solution is to just do it like Vulkan expects us to do it.

### Detailed usage

The functions you call in your program are actually just global function variables of their respective types.
In the following, "load" means that we set these globals.

There are three groups of functions the bindings:
1. Loader (These don't require a `VkInstance`)
2. Instance (These require a `VkInstance`)
3. Device (These require a `VkDevice` (or its child like e.g. a `VkQueue`))

the first call to `load_proc_addresses` is used to load the loader functions.
Then once you have the `VkInstance`, you can load groups 2 and  3.
Then you can optionally load group 3 again using a device.

This avoids the indirection that is mentioned in the spec.

If you have multiple logical devices, you can't do that with the global function variables. You can either just load with the instance and use those, or you can use a VTable for each device. The VTable struct is provided and one of the `load_proc_addresses` takes that as argument and loads into it.
