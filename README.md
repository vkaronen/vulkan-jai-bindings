# Vulkan Bindings For Jai

## Warning!

As of writing this README, there has been zero testing. That will change in the next few days.

## What's better about this fork?

- Basically, the previous method of providing the actual functions is limited. On linux for example, many functions provided by extensions weren't available.
- Faster: these bindings allow you to load the device specific function pointers that avoid some indirection overhead.
- Updated headers to 1.4.313.

## Usage

### Generating
run:
```sh
jai generate.jai
```

If it worked it should print a gazillion stripped functions and then at the end it should report zero functions along with more sensible numbers for the structs etc.

### Using the bindings
Just import the module as usual.

The functions need some more setup. I encourage you to read [why it works like this](#learn-more), but here is the usual way to do it:
1. call `load_global_proc_addresses`. Now you can call a small set of functions related to instance creation.
2. After creating the instance, you can call `load_instance_proc_addresses` with the instance as argument. Now you can call any function (taking into account which extensions you have enabled of course).
3. After creating the device, you can call `load_device_proc_addresses` yet again with the device as argument (NOTE: only do this if you only ever use this same `VkDevice` in your entire program OR you know what you are doing).

Step 3 is optional (and recommended) and slightly more performant.

@Todo: make an example

### Platform support
There are a number of header files that are optionally included in the bindings generation, and they mostly correspond to different platforms.
Internally, these options are toggled by passing specific defines to the bindings generator. These defines are found in `source/vulkan.h`.

By default Windows includes beta extensions and Win32. Linux includes beta extensions, xcb, xlib, wayland and android. MacOS includes beta extensions, ios, macos and metal.

If these includes are enough to cover your applications needs, you don't need to generate the bindings!

If you need something else included, you should modify `generate.jai` accordingly.

Beta extensions being included is just because it doesn't hurt to have more (Also StructureType default value assignment doesn't work as well if beta isn't included)!

### MacOS
I don't have a device with MacOS, and I don't know anything about running Vulkan on it. If you want to use these bindings, you need to at least add a declaration for `libvulkan` to point to where the vulkan loader is (and generate the bindings of course).

## Learn more

LunarG has a very helpful page on this: [Interfacing with Vulkan functions](https://vulkan.lunarg.com/doc/view/1.3.250.1/windows/LoaderApplicationInterface.html#interfacing-with-vulkan-functions)
As always when working with Vulkan, we can consult the [spec](https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html#initialization-functionpointers) (specifically section 4.1).

### Detailed usage
The Vulkan functions exported by these bindings are actually just global function variables of their respective types.

The different `load_X_proc_addresses` are convenience functions for setting these global variables to the function pointers that we get from the Vulkan loader.

The only Vulkan function that the module exports directly is `vkGetInstanceProcAddr` which we get from the Vulkan loader that comes with the user's Vulkan driver installation. This way we don't have to distribute a loader with these bindings.

If you have multiple logical devices, you can't just load with `load_device_proc_addresses`. You can either just load with `load_instance_proc_addresses` and use those, or you can use a VTable for each device. The VTable struct is provided and `load_vtable_proc_addresses` takes that as argument and loads into it.
