// MIT License - Copyright (c) 2022 Hamad Almamari
// Modified by Ryan Capote for Vulkan 1.3
// Modified by Veikka Karonen for Vulkan 1.4

// Tested with vulkan 1.0 and 1.2
// You can use this file to generate any version of vulkan bindings.
// You only need to set the vulkan.h path, and specify different defines if the default for your OS doesn't work.

// config
AT_COMPILE_TIME   :: true;
vulkan_h_location :: "source/vulkan.h";


// These are all the defines used in vulkan.h
// This set of defines isn't actually used anywhere, but you could if you provided all of the required system headers.
// (The generator will yell at you if you don't have them)
ALL_ARGS :: string.[
    "-DVK_ENABLE_BETA_EXTENSIONS",
    "-DVK_USE_PLATFORM_ANDROID_KHR",
    "-DVK_USE_PLATFORM_WAYLAND_KHR",
    "-DVK_USE_PLATFORM_XCB_KHR",
    "-DVK_USE_PLATFORM_XLIB_KHR",
    "-DVK_USE_PLATFORM_IOS_MVK",
    "-DVK_USE_PLATFORM_MACOS_MVK",
    "-DVK_USE_PLATFORM_METAL_EXT",
    "-DVK_USE_PLATFORM_VI_NN",
    "-DVK_USE_PLATFORM_FUCHSIA",
    "-DVK_USE_PLATFORM_WIN32_KHR",
    "-DVK_USE_PLATFORM_DIRECTFB_EXT",
    "-DVK_USE_PLATFORM_XLIB_XRANDR_EXT",
    "-DVK_USE_PLATFORM_GGP",
    "-DVK_USE_PLATFORM_SCREEN_QNX",
    "-DVK_USE_PLATFORM_SCI",
];

/*
    These are the default args selected based on your OS. They all enable beta extensions, which only means that
    structs and function pointers are generated. Generating without it defined is not possible currently, because
    some structs need to set their sType field to a value that won't be generated without the beta define.

    Other option would be to have the generator leave the sType as some default value, but then the user can't be
    certain that their sType is always correctly initialized.
*/

LINUX_ARGS :: string.[
    "-DVK_ENABLE_BETA_EXTENSIONS",
    "-DVK_USE_PLATFORM_ANDROID_KHR",
    "-DVK_USE_PLATFORM_WAYLAND_KHR",
    "-DVK_USE_PLATFORM_XCB_KHR",
    "-DVK_USE_PLATFORM_XLIB_KHR",
];

// @Untested
WINDOWS_ARGS :: string.[
    "-x",
    "c",
    "-DWIN32_LEAN_AND_MEAN",
    "-DVK_ENABLE_BETA_EXTENSIONS",
    "-DVK_USE_PLATFORM_WIN32_KHR",
];

// @Untested
MACOS_ARGS :: string.[
    "-DVK_ENABLE_BETA_EXTENSIONS",
    "-DVK_USE_PLATFORM_IOS_MVK",
    "-DVK_USE_PLATFORM_MACOS_MVK",
    "-DVK_USE_PLATFORM_METAL_EXT",
];

#if OS == .WINDOWS {
    DEFAULT_ARGS :: WINDOWS_ARGS;
    GENERATED_FILE :: "generated_windows.jai";
    GENERATED_FUNC_FILE :: "generated_funcs_windows.jai";
} else #if OS == .LINUX {
    DEFAULT_ARGS :: LINUX_ARGS;
    GENERATED_FILE :: "generated_linux.jai";
    GENERATED_FUNC_FILE :: "generated_funcs_linux.jai";
} else #if OS == .MACOS {
    DEFAULT_ARGS :: MACOS_ARGS;
    GENERATED_FILE :: "generated_macos.jai";
    GENERATED_FUNC_FILE :: "generated_funcs_macos.jai";
}


#if AT_COMPILE_TIME {
    #run {
        set_build_options_dc(.{do_output=false});
        if !generate_bindings() {
            compiler_set_workspace_status(.FAILED);
        }
    }
} else {
    #import "System";

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        if !generate_bindings() {
            exit(1);
        }
    }
}

//--------------------

OMIT_LIST :: string.[
    // These are defined manually:
    "VK_NULL_HANDLE",
    "VK_TRUE",
    "VK_FALSE",
    "VK_WHOLE_SIZE",
    "VK_ATTACHMENT_UNUSED",
    "VK_QUEUE_FAMILY_IGNORED",
    "VK_REMAINING_ARRAY_LAYERS",
    "VK_REMAINING_MIP_LEVELS",
    "VK_SUBPASS_EXTERNAL",
    "VK_MAX_PHYSICAL_DEVICE_NAME_SIZE",
    "VK_UUID_SIZE",
    "VK_MAX_MEMORY_TYPES",
    "VK_MAX_MEMORY_HEAPS",
    "VK_MAX_EXTENSION_NAME_SIZE",
    "VK_MAX_DESCRIPTION_SIZE",
];


generate_bindings :: () -> bool {
    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        output_filename = GENERATED_FILE;

        for DEFAULT_ARGS {
            array_add(*extra_clang_arguments, it);
        }

        array_add(*source_files, vulkan_h_location);

        generate_library_declarations = false;
        omit_global_declarations = false;
        will_print_bindings = generate_funcs;

        visitor     = vulkan_visitor;
        generate_compile_time_struct_checks = false;
        log_unsupported = true;
    }

    return generate_bindings(opts, output_filename);
}

available_flag_bits: Table(string, *Enum);
struct_type_decl: *Enum;

vulkan_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    // Omit header definitions (ex: VULKAN_H_)
    if decl.kind == .MACRO_DEFINITION && ends_with(decl.name, "_H_") {
        // print("MACRO_DEFINITION removed: %\n", decl.name);
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }


    // Is this guaranteed?
    if decl.type {

        // There is a risk here if for example 'Window' is also used in some other header unrelated to Xlib.
        // But currently this works fine, there are only three lines total where these types appear.
        search_and_replace_type_by_name(decl.type, "Display", "Xlib_Display");
        search_and_replace_type_by_name(decl.type, "Window", "Xlib_Window");
        search_and_replace_type_by_name(decl.type, "VisualID", "Xlib_VisualID");

        if decl.type.type_of_function {
            type := decl.type.type_of_function;

            if type.arguments.count > 0 {
                if type.arguments[0].type.type_of_typedef {
                    type_name := type.arguments[0].type.type_of_typedef.name;
                    if (type_name == "VkDevice" || type_name == "VkQueue" || type_name == "VkCommandBuffer") && decl.name != "vkGetDeviceProcAddr" {
                        array_add(*device_funcs, decl.name);
                    } else if (type_name == "VkInstance" || type_name == "VkPhysicalDevice") || decl.name == "vkGetDeviceProcAddr" {
                        array_add(*instance_funcs, decl.name);
                    }
                }

            }

            if decl.kind == .FUNCTION {
                decl.decl_flags |= .OMIT_FROM_OUTPUT;
            }
        }
        // This is pretty unnecessary.
        if decl.name == {
            case "PFN_vkCreateInstance"; #through;
            case "PFN_vkDebugUtilsMessengerCallbackEXT"; #through;
            case "PFN_vkDeviceMemoryReportCallbackEXT"; #through;
            case "PFN_vkEnumerateInstanceExtensionProperties"; #through;
            case "PFN_vkEnumerateInstanceLayerProperties"; #through;
            case "PFN_vkEnumerateInstanceVersion";
                array_add(*loader_funcs, slice(decl.name, 4, decl.name.count - 4));
        }
    }

    // Omit our OMIT_LIST
    if !parent_decl && array_find(OMIT_LIST, decl.name) {
        //print("OMIT_LIST: %\n", decl.name);
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }

    if decl.kind == .ENUM {
        en := cast(*Enum)decl;
        if en.name == "VkStructureType" {
            struct_type_decl = en; // Save for later
        }
        
        // Almost all enums should be unsigned
        if en.type && decl.name != "VkResult" {
            if en.type.size == {
                case 1;
                    en.type = context.generator.type_def_u8;
                case 2;
                    en.type = context.generator.type_def_u16;
                case 4;
                    en.type = context.generator.type_def_u32;
                case 8;
                    en.type = context.generator.type_def_u64;
            }
        }

        if contains(decl.name, "FlagBits") {
            en.flags |= .IS_ENUM_FLAGS;
            en.flags |= .VALUES_IN_HEX;

            // Remember this so we can replace the generic VkFlags aliases with the actual enum_flag's type below. :VkFlags
            table_add(*available_flag_bits, decl.name, en);
        }
    }

    // Replace typedef which has "VkFlags" as value. :VkFlags
    // VkAccessFlags :: VkFlags   ->   VkAccessFlags :: VkAccessFlagBits;
    // We don't change the name of the FlagBits enum directly because both the ...FlagBits and the ...Flags aliases are used in declarations.
    if decl.kind == .TYPEDEF && decl.type.type_of_typedef &&  decl.type.type_of_typedef.name == "VkFlags" {
        //print("TYPEDEF(VkFlags):%\n", << decl.name);
        flags_name := replace(decl.name, "Flags", "FlagBits");
        enum_decl, found := table_find(*available_flag_bits, flags_name);
        if found {
            type := New(CType);
            type.type_of_enum = enum_decl;
            type.size = enum_decl.type.size;
            decl.type = type;
        }
    }

    // Set the default value for sType.
    if parent_decl && parent_decl.kind == .STRUCT && parent_decl.name != "VkBaseInStructure" && parent_decl.name != "VkBaseOutStructure" && 
            decl.kind == .DECLARATION && decl.name == "sType" {

        enum_value_name := get_sType_default_value_from_struct_name(parent_decl.name);

        // Vulkan has inconsisant naming for things, so the generator can't find these enum values because it splits or doesn't split
        // numbers correctly in newer cases. This manually changes the name of the enum so the generator can find it.
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_11_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_1_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_11_PROPERTIES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_1_PROPERTIES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_12_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_2_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_12_PROPERTIES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_13_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_3_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_13_PROPERTIES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_3_PROPERTIES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_14_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_4_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_VULKAN_14_PROPERTIES" then enum_value_name = "PHYSICAL_DEVICE_VULKAN_1_4_PROPERTIES";
        if enum_value_name == "PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTCHDR_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_HDR_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_RGB_A_10_X_6_FORMATS_FEATURES_EXT" then enum_value_name = "PHYSICAL_DEVICE_RGBA10X6_FORMATS_FEATURES_EXT";
        if enum_value_name == "PHYSICAL_DEVICE_IMAGE_2_D_VIEW_OF_3_D_FEATURES_EXT" then enum_value_name = "PHYSICAL_DEVICE_IMAGE_2D_VIEW_OF_3D_FEATURES_EXT";
        if enum_value_name == "PHYSICAL_DEVICE_IMAGE_SLICED_VIEW_OF_3_D_FEATURES_EXT" then enum_value_name = "PHYSICAL_DEVICE_IMAGE_SLICED_VIEW_OF_3D_FEATURES_EXT";

	/*
        if enum_value_name == "PHYSICAL_DEVICE_SHADER_ATOMIC_INT_64_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_SHADER_IMAGE_ATOMIC_INT_64_FEATURES_EXT" then enum_value_name = "PHYSICAL_DEVICE_SHADER_IMAGE_ATOMIC_INT64_FEATURES_EXT";
        if enum_value_name == "PHYSICAL_DEVICE_SHADER_FLOAT_16_INT_8_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES";
        if enum_value_name == "PHYSICAL_DEVICE_INDEX_TYPE_UINT_8_FEATURES_EXT" then enum_value_name = "PHYSICAL_DEVICE_INDEX_TYPE_UINT8_FEATURES_EXT";
        if enum_value_name == "PHYSICAL_DEVICE_INDEX_TYPE_UINT_8_FEATURES_KHR" then enum_value_name = "PHYSICAL_DEVICE_INDEX_TYPE_UINT8_FEATURES_KHR";
        if enum_value_name == "PHYSICAL_DEVICE_INDEX_TYPE_UINT_8_FEATURES" then enum_value_name = "PHYSICAL_DEVICE_INDEX_TYPE_UINT8_FEATURES";
        if enum_value_name == "VIDEO_DECODE_H_264_PROFILE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H264_PROFILE_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_264_CAPABILITIES_KHR" then enum_value_name = "VIDEO_DECODE_H264_CAPABILITIES_KHR";
        if enum_value_name == "VIDEO_DECODE_H_264_SESSION_PARAMETERS_ADD_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H264_SESSION_PARAMETERS_ADD_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_264_SESSION_PARAMETERS_CREATE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H264_SESSION_PARAMETERS_CREATE_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_264_PICTURE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H264_PICTURE_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_264_DPB_SLOT_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H264_DPB_SLOT_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_264_PROFILE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H264_PROFILE_INFO_KHR";

	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_CAPABILITIES_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_CREATE_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_ADD_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_PICTURE_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_DPB_SLOT_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_NALU_SLICE_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_GOP_REMAINING_FRAME_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_PROFILE_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_RATE_CONTROL_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_RATE_CONTROL_LAYER_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_CREATE_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_QUALITY_LEVEL_PROPERTIES_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_GET_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_SESSION_PARAMETERS_FEEDBACK_INFO_KHR;
	VK_STRUCTURE_TYPE_VIDEO_ENCODE_H264_QUANTIZATION_MAP_CAPABILITIES_KHR;
	VK_STRUCTURE_TYPE_VIDEO_DECODE_H264_INLINE_SESSION_PARAMETERS_INFO_KHR;
        if enum_value_name == "VIDEO_DECODE_H_265_PROFILE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H265_PROFILE_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_265_CAPABILITIES_KHR" then enum_value_name = "VIDEO_DECODE_H265_CAPABILITIES_KHR";
        if enum_value_name == "VIDEO_DECODE_H_265_SESSION_PARAMETERS_ADD_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H265_SESSION_PARAMETERS_ADD_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_265_SESSION_PARAMETERS_CREATE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H265_SESSION_PARAMETERS_CREATE_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_265_PICTURE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H265_PICTURE_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_265_DPB_SLOT_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H265_DPB_SLOT_INFO_KHR";
        if enum_value_name == "VIDEO_DECODE_H_265_PROFILE_INFO_KHR" then enum_value_name = "VIDEO_DECODE_H265_PROFILE_INFO_KHR";
	*/



        enum_value: *Enum.Enumerate = *struct_type_decl.enumerates[0];
        for * struct_type_decl.enumerates {
            if it.output_name == enum_value_name {
                enum_value = it;
                break;
            }
        }
        assert(enum_value != null, "Could not find % enum value for \"%\"", struct_type_decl.name, enum_value_name);

        literal := New(Literal);
        literal.literal_kind = .ENUM;
        literal.enum_type = struct_type_decl;
        literal.enum_value = enum_value;
        decl.expression = literal;
    }

    return .RECURSE;
}

get_sType_default_value_from_struct_name :: (name: string) -> string {
    assert(name.count >= 3);

    is_upper :: (byte: u8) -> bool {
        if byte >= #char "A" && byte <= #char "Z" return true;
        return false;
    }

    is_num :: (byte: u8) -> bool {
        if byte >= #char "0" && byte <= #char "9" return true;
        return false;
    }

    builder: String_Builder;
    append(*builder, name[2]);
    for i:3..name.count-1 {
        if is_upper(name[i]) {
            is_first_uppercase := !is_upper(name[i-1]);
            is_end_of_uppercase_word := (i != name.count-1 && !is_upper(name[i+1]) && !is_num(name[i+1]));
            is_bit_count := is_num(name[i-1]) && slice(name, i, 3) == "Bit";
            if (is_first_uppercase || is_end_of_uppercase_word) && !is_bit_count {
                append(*builder, #char "_");
            } else if (i >= 4 && slice(name, i-4, 4) == "AABB") { // Special case hack for names involing AABB
                append(*builder, #char "_");
            }
            append(*builder, name[i]);
        } else if is_num(name[i]) {
            if !is_num(name[i-1]) { 
                if slice(name, i-1, 3) == "H26" {} // Special case for H264 and H265
                else if slice(name, i-2, 2) == "AV" {} // AV1
                else if (i >= 4 && slice(name, i-4, 4) == "loat" && name[i] != #char "2") {} // Bfloat and Float, but not float 2 features
                else if (slice(name, i-4, 4) == "Uint") {}
                else if (slice(name, i-3, 3) == "Int") {}
                else append(*builder, #char "_");
            }
            append(*builder, name[i]);
        } else {
            append(*builder, to_upper(name[i]));
        }
    }

    return builder_to_string(*builder);
}


// Replaces typedefs with better names (example: Xlib uses a type called 'Display', we change the output_name to XlibDisplay)
search_and_replace_type_by_name :: (declaration_type: *CType, search: string, replace: string) {
    type := declaration_type;

    while true {
        if type.pointer_to {
            type = type.pointer_to;
        } else if type.type_of_typedef {
            if type.type_of_typedef.name == search then type.type_of_typedef.output_name = replace;
            break;
        } else if type.type_of_function {
            // Arguments are declarations and should be passed to this function separately
            if type.type_of_function.return_type then type = type.type_of_function.return_type;
        } else if type.array_element_type {
            type = type.array_element_type;
        } else {
            // Number or struct (again struct fields are declarations and are passed here separately)
            break;
        }
    }
}


device_funcs: [..]string;
instance_funcs: [..]string;
loader_funcs: [..]string;



generate_funcs :: () {
    builder: String_Builder;
    init_string_builder(*builder);

    write_func_variable_declaration :: (builder: *String_Builder, func_name: string, indent := "") {
        append(builder, indent);
        append(builder, func_name);
        append(builder, ": PFN_");
        append(builder, func_name);
        append(builder, ";\n");
    }

    write_func_variable_assignment_device :: (builder: *String_Builder, func_name: string, prefix := "") {
        append(builder, prefix);
        append(builder, func_name);
        append(builder, " = xx vkGetDeviceProcAddr(device, \"");
        append(builder, func_name);
        append(builder, "\");\n");
    }
    write_func_variable_assignment_instance :: (builder: *String_Builder, func_name: string, prefix := "") {
        append(builder, prefix);
        append(builder, func_name);
        append(builder, " = xx vkGetInstanceProcAddr(instance, \"");
        append(builder, func_name);
        append(builder, "\");\n");
    }
    write_func_variable_assignment_loader :: (builder: *String_Builder, func_name: string, prefix := "") {
        append(builder, prefix);
        append(builder, func_name);
        append(builder, " = xx vkGetInstanceProcAddr(null, \"");
        append(builder, func_name);
        append(builder, "\");\n");
    }

    for loader_funcs {
        write_func_variable_declaration(*builder, it);
    }
    for instance_funcs {
        write_func_variable_declaration(*builder, it);
    }
    for device_funcs {
        write_func_variable_declaration(*builder, it);
    }

    append(*builder, "\n\nDevice_VTable :: struct {\n");

    for device_funcs {
        write_func_variable_declaration(*builder, it, "    ");
    }

    append(*builder, "};\n\nload_proc_addresses_vtable :: (device: VkDevice, vtable: *Device_VTable) {\n");

    for device_funcs {
        write_func_variable_assignment_device(*builder, it, "    vtable.");
    }

    append(*builder, "}\n\nload_device_proc_addresses :: (device: VkDevice) {\n");

    for device_funcs {
        write_func_variable_assignment_device(*builder, it, "    ");
    }

    append(*builder, "}\n\nload_instance_proc_addresses :: (instance: VkInstance) {\n");

    for instance_funcs {
        write_func_variable_assignment_instance(*builder, it, "    ");
    }
    for device_funcs {
        write_func_variable_assignment_instance(*builder, it, "    ");
    }

    append(*builder, "}\n\nload_global_proc_addresses :: (vk_get_instance_proc_addr: *void) {\n    vkGetInstanceProcAddr = xx vk_get_instance_proc_addr;\n\n");

    for loader_funcs {
        write_func_variable_assignment_loader(*builder, it, "    ");
    }

    append(*builder, "}\n");


    success := write_entire_file(GENERATED_FUNC_FILE, *builder);
}

#scope_file
#import "Basic";
#import "Compiler";
#import "Check";
#import "Bindings_Generator";
#import "File";
#import "String";
#import "Hash_Table";
