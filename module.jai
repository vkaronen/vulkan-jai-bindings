/*

Vulkan API bindings.

WARNING: These Vulkan bindings are mostly unused and untested for now.

*/


VK_NULL_HANDLE                    :: null;

VK_TRUE:                   VkBool32: 1;
VK_FALSE:                  VkBool32: 0;

VK_WHOLE_SIZE:             u64: xx ~0;
VK_ATTACHMENT_UNUSED:      u32: 0xffff_ffff;
VK_QUEUE_FAMILY_IGNORED:   u32: 0xffff_ffff;
VK_REMAINING_ARRAY_LAYERS: u32: 0xffff_ffff;
VK_REMAINING_MIP_LEVELS:   u32: 0xffff_ffff;
VK_SUBPASS_EXTERNAL:       u32: 0xffff_ffff;

VK_MAX_PHYSICAL_DEVICE_NAME_SIZE: u32: 256;
VK_UUID_SIZE:                     u32: 16;
VK_MAX_MEMORY_TYPES:              u32: 32;
VK_MAX_MEMORY_HEAPS:              u32: 16;
VK_MAX_EXTENSION_NAME_SIZE:       u32: 256;
VK_MAX_DESCRIPTION_SIZE:          u32: 256;

// These defines are deprecated by vulkan 1.2:
VK_MAKE_VERSION :: (major: u32, minor: u32, patch: u32) -> u32 {
    return (major << 22) | (minor << 12) | patch;
}
VK_VERSION_MAJOR :: (version: u32) -> u32 { return version >> 22; }
VK_VERSION_MINOR :: (version: u32) -> u32 { return (version >> 12) & 0x3ff; }
VK_VERSION_PATCH :: (version: u32) -> u32 { return version & 0xfff; }

//VK_HEADER_VERSION :: 313;

VK_API_VERSION_1_0 :: #run VK_MAKE_API_VERSION(0, 1, 0, 0);
VK_API_VERSION_1_1 :: #run VK_MAKE_API_VERSION(0, 1, 1, 0);
VK_API_VERSION_1_2 :: #run VK_MAKE_API_VERSION(0, 1, 2, 0);
VK_API_VERSION_1_3 :: #run VK_MAKE_API_VERSION(0, 1, 3, 0);
VK_API_VERSION_1_4 :: #run VK_MAKE_API_VERSION(0, 1, 4, 0);
VK_API_VERSION_COMPLETE :: #run VK_MAKE_API_VERSION(0, 1, 4, VK_HEADER_VERSION);

// These are the new versions:
VK_MAKE_API_VERSION :: (variant: u32, major: u32, minor: u32, patch: u32) -> u32 {
    return (variant << 29) | (major << 22) | (minor << 12) | patch;
}

VK_API_VERSION_VARIANT :: (version: u32) -> u32 { return (version >> 29); }
VK_API_VERSION_MAJOR   :: (version: u32) -> u32 { return (version >> 22) & 0x7f; }
VK_API_VERSION_MINOR   :: (version: u32) -> u32 { return (version >> 12) & 0x3ff; }
VK_API_VERSION_PATCH   :: (version: u32) -> u32 { return version & 0xfff; }

VK_MAKE_VIDEO_STD_VERSION :: (major: u32, minor: u32, patch: u32) -> u32 {
    return (major << 22) | (minor << 12) | patch;
}
VK_STD_VULKAN_VIDEO_CODEC_AV1_DECODE_API_VERSION_1_0_0 :: #run VK_MAKE_VIDEO_STD_VERSION(1, 0, 0);
VK_STD_VULKAN_VIDEO_CODEC_AV1_DECODE_SPEC_VERSION :: VK_STD_VULKAN_VIDEO_CODEC_AV1_DECODE_API_VERSION_1_0_0;
VK_STD_VULKAN_VIDEO_CODEC_AV1_ENCODE_API_VERSION_1_0_0 :: #run VK_MAKE_VIDEO_STD_VERSION(1, 0, 0);
VK_STD_VULKAN_VIDEO_CODEC_AV1_ENCODE_SPEC_VERSION :: VK_STD_VULKAN_VIDEO_CODEC_AV1_DECODE_API_VERSION_1_0_0;

VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0 :: #run VK_MAKE_VIDEO_STD_VERSION(1, 0, 0);
VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_SPEC_VERSION :: VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0;
VK_STD_VULKAN_VIDEO_CODEC_H264_ENCODE_API_VERSION_1_0_0 :: #run VK_MAKE_VIDEO_STD_VERSION(1, 0, 0);
VK_STD_VULKAN_VIDEO_CODEC_H264_ENCODE_SPEC_VERSION :: VK_STD_VULKAN_VIDEO_CODEC_H264_DECODE_API_VERSION_1_0_0;

VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0 :: #run VK_MAKE_VIDEO_STD_VERSION(1, 0, 0);
VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_SPEC_VERSION :: VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0;
VK_STD_VULKAN_VIDEO_CODEC_H265_ENCODE_API_VERSION_1_0_0 :: #run VK_MAKE_VIDEO_STD_VERSION(1, 0, 0);
VK_STD_VULKAN_VIDEO_CODEC_H265_ENCODE_SPEC_VERSION :: VK_STD_VULKAN_VIDEO_CODEC_H265_DECODE_API_VERSION_1_0_0;


#if OS == .WINDOWS {
    #load "generated_windows.jai";
    #load "generated_funcs_windows.jai";
} else #if OS == .LINUX {
    #load "generated_linux.jai";
    #load "generated_funcs_linux.jai";
} else #if OS == .MACOS {
    #load "generated_macos.jai";
    #load "generated_funcs_macos.jai";
}



// Various types the bindings generator couldn't simplify automatically.
// They are buried deep in the system includes.
xcb_connection_t :: struct {};
xcb_window_t :: u32;
xcb_visualid_t :: u32;

Xlib_Display :: struct {};
Xlib_Window :: u32;
Xlib_VisualID :: u32;

// @Todo: I think this is related to windows?
#scope_module

size_t  :: u64;
