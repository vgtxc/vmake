-- lastEdit=>2026.01.08-22:52
-- creat: 2026.01.08
-- (01)软件相关信息
vmake_info = {
    name = "vmake",
    version = "0.0.0",
    author = "vgtxc",
    email = "<email>",
    url = "https://github.com/vgtxc/vmake",
};
-- (04)配置内置工具
vmake_tool = {
    lua = {
        sys_env = {
            cc = "gcc",
            cxx = "g++",
            -- linkflags = "-shared"
        },
    },
    git = {active_flag = true,},    
    cmake = {active_flag = true,},    
    xmake = {active_flag = true,},    
    vcpkg = {
        active_flag = true,
        sys_env = {
            vcpkg_triplet = "x64-mingw-static",
            vcpkg_default_triplet = "x64-mingw-static",
            vcpkg_default_host_triplet = "x64-mingw-static",
        }
    },    
    mingw_w64 = {active_flag = false,},    
    mingw_llvm = {active_flag = true,},    
    msvc_llvm = {active_flag = true,},    
    nodejs = {active_flag = true,},    
    python = {active_flag = false,},    
    python_enbed = {active_flag = false,},    
    rust = {active_flag = true,},    
    golang = {active_flag = true,},    
    java = {active_flag = true,},    
    zig = {active_flag = true,},    
    vlang = {active_flag = false},    
};