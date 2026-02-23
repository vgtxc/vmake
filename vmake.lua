-- lastEdit=>2026.02.22-23:36
-- lastEdit=>2026.02.22-13:31
-- lastEdit=>2026.02.21-23:56 
-- lastEdit=>2026.02.18-22:52 
-- lastEdit=>2026.02.17-23:44 
-- lastEdit=>2026.02.13-23:28
-- lastEdit=>2026.02.09-15:32
-- lastEdit=>2026.01.27-21:16
-- lastEdit=>2026.01.24-24:00
-- lastEdit=>2026.01.08-22:56
-- creat: 2026.01.08
-- aut: vgtxc
-- ver: 0.0.1#2026.02.22-13:33
-- ver: 0.0.0#2026.02.22-13:33
-- ver: v.src#2026.01.24-22:46
--[[
    实现逻辑:
        01.初始化配置,读取<vmake_root/config.lua>,读取项目下的<vmake_proj_root/vmake_proj.lua>, 更新内置配置
        02.解析命令行参数, 获取命令行参数, 匹配命令, 调用对应函数
    核心功能结构:
        vmake_info: 软件信息
        vmake_tool: 软件配置（包含基础配置和SDK配置）
        vmake_sys: 系统功能函数
        vmake_cmd: 软件命令配置
        vmake_pkg: 编译器工具链第三方包配置
        注意: 涉及脚本创建的函数
            vmake_sys.set_vmake_tool_env_cat_table();
            vmake_sys.set_vmake_tool_env_gen_table();
            vmake_sys.set_vmake_tool_env_gen_str();
            vmake_sys.set_vmake_tool_env_gen_shell();
            vmake_sys.set_vmake_tool_env_gen_term();
            vmake_cmd.setenv();
            vmake_cmd.creat_batch();
    核心功能函数:
        01.vmake_init: 软件初始化配置
        02.analyze_config: 解析软件配置文件
        03.analyze_term: 解析命令行参数
        04.analyze_proj: 解析vmake_proj.lua配置文件
]]
-- *****************************************************************
-- *****************************************************************
-- *****************************************************************
-- 软件根路径
-- 获取脚本文件或可执行文件所在的实际路径，而非当前工作目录
-- 支持 .lua 文件和编译后的 .exe 文件
local vmake_root_gen = function()
    local function normalize_path(path)
        path = path:gsub("\\", "/");
        if path:sub(-1) ~= "/" then path = path .. "/"; end;
        return path;
    end
    local function get_exe_dir(exe_path)
        if not exe_path or exe_path == "" then return nil; end;
        -- 处理相对路径
        if exe_path:sub(1, 1) ~= "/" and exe_path:sub(2, 2) ~= ":" then
            exe_path = io.popen("cd"):read("*l") .. "\\" .. exe_path;
        end;
        -- 提取目录
        local dir = exe_path:match("(.*[/\\])");
        return dir and normalize_path(dir) or nil;
    end
    -- 优先使用 arg[0]，失败则使用 debug.getinfo
    local retval = get_exe_dir(arg[0]) or get_exe_dir(debug.getinfo(1, "S").source:gsub("^@", "")) or normalize_path(io.popen("cd"):read("*l"));
    return retval;
end;
-- vmake项目所在的路径
vmake_root = vmake_root_gen();
-- 第三方库
-- lua_module_root = vmake_root .. "/tool/lua/luarocks/lib/lua/5.4/?.dll";
-- lua_share_root = vmake_root .. "/tool/lua/luarocks/share/lua/5.4/?.lua";
-- package.path = lua_share_root;  -- 引入第三方库, 源文件
-- package.cpath = lua_module_root;    -- 引入第三方库, 动态库
-- vmake_lua_module = {
--     lfs = require("lfs"),
--     penlight = require("pl.path"),
-- };
-- 软件信息
vmake_info = {
    name = "vmake",
    version = "v.src#2026.01.24-22:46",
    author = "vgtxc",
    email = "void",
    description = "vmake is a make tool",
    license = "MIT",
    url = "https://github.com/vmake-dev/vmake",
};
-- 软件工具配置（合并vmake_sdk字段）
-- (01)内置工具
-- (02)下载工具
-- 每个工具包含：基础字段（url, download_url, install_flag, excu, root, config, cache, version）
--            + SDK字段（active_flag, pkg_root, pkg_manager_root, pkg_manager_excu,
--                     bin_root, include_root, lib_root, share_root, sys_env）
vmake_tool = {
    -- vmake元素添加模板
    -- vmake_element_template = {
    --     -- 基础字段
    --     url = nil,  -- 官网地址
    --     download_url = nil, -- 下载地址, 优先下载压缩包格式
    --     install_flag = false,   -- 是否安装<必要字段>
    --     excu = nil, -- 执行文件<必要字段>
    --     root = nil, -- 安装路径<必要字段>
    --     config = nil,   -- 配置文件
    --     cache = nil,    -- 缓存路径
    --     version = nil,  -- 版本<必要字段>
    --     -- SDK字段
    --     active_flag = false, -- 是否激活<必要字段>
    --     pkg_root = nil,  -- 包安装根目录
    --     pkg_manager_root = nil, -- 包管理器根目录
    --     pkg_manager_excu = nil, -- 包管理器执行文件
    --     bin_root = nil, -- bin目录
    --     include_root = nil, -- include目录
    --     lib_root = nil, -- lib目录
    --     share_root = nil, -- share目录
    --     sys_env = {}, -- 环境变量配置
    -- },
    vmake = {
        -- 基础字段
        url = nil,  -- 官网地址
        download_url = nil, -- 下载地址, 优先下载压缩包格式
        install_flag = false,   -- 是否安装
        excu = nil, -- 执行文件
        root = nil, -- 安装路径
        config = nil,   -- 配置文件
        cache = nil,    -- 缓存路径
        version = "src",  -- 版本
        -- SDK字段
        active_flag = true, -- 是否激活
        pkg_root = nil,  -- 包安装根目录
        pkg_manager_root = nil, -- 包管理器根目录
        pkg_manager_excu = nil, -- 包管理器执行文件
        bin_root = nil, -- bin目录
        include_root = nil, -- include目录
        lib_root = nil, -- lib目录
        share_root = nil, -- share目录
        sys_env = {
            path = {
                vmake_root,
                vmake_root.."/script"
            },
        }, -- 环境变量配置
    },
    -- 7z<内置>
    a7z = {
        url = "https://www.7-zip.org/",
        download_url = "https://www.7-zip.org/a/7z2301-extra.7z",
        install_flag = true,
        excu = vmake_root .. "/tool/a7z/7za.exe",
        root = vmake_root .. "/tool/a7z",
        config = nil,
        cache = vmake_root .. "/tool/a7z/cache",
        version = "2301",
        active_flag = true,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/a7z",},
    },
    -- aria2<内置>
    aria2 = {
        url = "https://aria2.github.io/",
        download_url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/aria2/aria2c.exe",
        root = vmake_root .. "/tool/aria2",
        config = nil,
        cache = vmake_root .. "/tool/aria2/cache",
        version = "1.37.0",
        active_flag = true,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/aria2",},
    },
    -- pixi<内置>
    pixi = {
        url = "https://github.com/prefix-dev/pixi",
        download_url = "https://github.com/prefix-dev/pixi/releases/download/v0.63.2/pixi-x86_64-pc-windows-msvc.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/pixi/pixi.exe",
        root = vmake_root .. "/tool/pixi",
        config = nil,
        cache = vmake_root .. "/tool/pixi/cache",
        version = "0.63.2",
        active_flag = true,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/pixi",},
    },
    -- lua<内置>
    lua = {
        url = "https://www.lua.org/",
        download_url = {
            "https://sourceforge.net/projects/luabinaries/files/5.5.0/Tools%20Executables/lua-5.5.0_Win64_bin.zip/download",
            "https://sourceforge.net/projects/luabinaries/files/5.5.0/Windows%20Libraries/Dynamic/lua-5.5.0_Win64_dllw6_lib.zip/download",
        },
        luarocks_url = "https://luarocks.org/",
        luarocks_download_url = "https://github.com/luarocks/luarocks/releases/download/v3.12.2/luarocks-3.12.2-windows-64.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/lua/bin/lua.exe",
        root = vmake_root .. "/tool/lua",
        config = vmake_root .. "/tool/lua/luarocks/config.lua",
        cache = nil,
        version = "5.5.0",
        active_flag = true,
        pkg_root = vmake_root .. "/tool/lua/pkg",
        pkg_manager_root = vmake_root .. "/tool/lua/luarocks",
        pkg_manager_excu = vmake_root .. "/tool/lua/luarocks/luarocks.exe",
        bin_root = vmake_root .. "/tool/lua/bin",
        include_root = vmake_root .. "/tool/lua/include",
        lib_root = vmake_root .. "/tool/lua/lib",
        share_root = nil,
        sys_env = {
            lua_root = vmake_root .. "/tool/lua",
            lua_excu = vmake_root .. "/tool/lua/bin/lua.exe",
            lua_bindir = vmake_root .. "/tool/lua/bin",
            lua_incdir = vmake_root .. "/tool/lua/include",
            lua_libdir = vmake_root .. "/tool/lua/lib",
            luarocks_root = vmake_root .. "/tool/lua/luarocks",
            luarocks_config =  vmake_root .. "/tool/lua/luarocks/config.lua",
            path = {
                vmake_root .. "/tool/lua/bin",
                vmake_root .. "/tool/lua/luarocks",
            },
        },
    },
    -- git<通过内置命令下载>
    git = {
        url = "https://git-scm.com/",
        download_url = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe",
        install_flag = false,
        excu = vmake_root .. "/tool/git/bin/git.exe",
        root = vmake_root .. "/tool/git",
        config = nil,
        cache = vmake_root .. "/tool/git/cache",
        version = "2.52.0",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = {
                vmake_root .. "/tool/git",
                vmake_root .. "/tool/git/bin"
            },
        },
    },
    -- cmake<通过内置命令下载>
    cmake = {
        url = "https://github.com/Kitware/CMake",
        download_url = "https://github.com/Kitware/CMake/releases/download/v4.2.2/cmake-4.2.2-windows-x86_64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/cmake/bin/cmake.exe",
        root = vmake_root .. "/tool/cmake",
        config = nil,
        cache = nil,
        version = "4.2.2",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = vmake_root.."/tool/cmake/bin",
        },
    },
    -- xmake<通过内置命令下载>
    xmake = {
        url = "https://github.com/xmake-io/xmake",
        download_url = "https://github.com/xmake-io/xmake/releases/download/v3.0.6/xmake-v3.0.6.win64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/xmake/xmake.exe",
        root = vmake_root .. "/tool/xmake",
        config = nil,
        cache = nil,
        version = "3.0.6",
        active_flag = false,
        pkg_root = vmake_root .. "/tool/xmake/pkg",
        pkg_manager_root = vmake_root .. "/tool/xmake",
        pkg_manager_excu = vmake_root .. "/tool/xmake/xrepo.bat",
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/xmake",},
    },
    -- vcpkg<通过内置命令下载>
    vcpkg = {
        url = "https://github.com/microsoft/vcpkg",
        download_url = "https://github.com/microsoft/vcpkg/archive/refs/tags/2026.01.16.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/vcpkg/vcpkg.exe",
        root = vmake_root .. "/tool/vcpkg",
        config = nil,
        cache = nil,
        version = "2026.01.16",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = vmake_root .. "/tool/vcpkg",
            vcpkg_root = vmake_root .. "/tool/vcpkg",
        },
    },
    -- mingw_w64<通过内置命令下载>
    mingw_w64 = {
        url = "https://github.com/niXman/mingw-builds",
        download_url = "https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev0/x86_64-15.2.0-release-win32-seh-ucrt-rt_v13-rev0.7z",
        install_flag = false,
        excu = vmake_root .. "/tool/mingw_w64/bin/gcc.exe",
        root = vmake_root .. "/tool/mingw_w64",
        config = nil,
        cache = nil,
        version = "15.2.0",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/mingw_w64/bin",},
    },
    -- mingw_llvm<通过内置命令下载>
    mingw_llvm = {
        url = "https://github.com/mstorsjo/llvm-mingw",
        download_url = "https://github.com/mstorsjo/llvm-mingw/releases/download/20251216/llvm-mingw-20251216-msvcrt-i686.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/mingw_llvm/bin/gcc.exe",
        root = vmake_root .. "/tool/mingw_llvm",
        config = nil,
        cache = nil,
        version = "15.2.0",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/mingw_llvm/bin",},
    },
    -- msvc_llvm<通过内置命令下载>
    msvc_llvm = {
        url = "https://github.com/mstorsjo/llvm-mingw",
        download_url = {
            "https://github.com/backengineering/llvm-msvc/releases/download/llvm-msvc-v777.2.8/windows-llvm-msvc-PDB.zip.001",
            "https://github.com/backengineering/llvm-msvc/releases/download/llvm-msvc-v777.2.8/windows-llvm-msvc-PDB.zip.002",
        },
        install_flag = false,
        excu = vmake_root .. "/tool/msvc_llvm/bin/clang-cl.exe",
        root = vmake_root .. "/tool/msvc_llvm",
        config = nil,
        cache = nil,
        version = "777.2.8",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root.."/tool/msvc_llvm/bin",},
    },
    -- nodejs<通过内置命令下载>
    nodejs = {
        url = "https://nodejs.org",
        download_url = "https://nodejs.org/dist/v24.13.0/node-v24.13.0-win-x64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/nodejs/node.exe",
        root = vmake_root .. "/tool/nodejs",
        config = nil,
        cache = vmake_root .. "/tool/nodejs/cache",
        version = "24.13.0",
        active_flag = false,
        pkg_root = vmake_root .. "/tool/nodejs/pkg",
        pkg_manager_root = vmake_root .. "/tool/nodejs",
        pkg_manager_excu = vmake_root .. "/tool/nodejs/npm.cmd",
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = {
                vmake_root .. "/tool/nodejs",
                vmake_root .. "/tool/nodejs/pkg",
            },
            npm_config_cache = vmake_root .. "/tool/nodejs/cache",
            npm_config_prefix = vmake_root .. "/tool/nodejs/pkg",
        },
    },
    -- python<通过内置命令下载>
    python = {
        url = "https://www.python.org/",
        download_url = "https://github.com/vgtxc/python_portable/releases/download/v3.14.3/win-x64-v3.14.3.7z",
        install_flag = false,
        excu = vmake_root .. "/tool/python/python.exe",
        root = vmake_root .. "/tool/python",
        config = nil,
        cache = nil,
        version = "3.14.3",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = {
                vmake_root.."/tool/python",
                vmake_root.."/tool/python/Scripts"
            }
        },
    },
    -- python_enbed<通过内置命令下载>
    python_enbed = {
        url = "https://www.python.org/",
        download_url = "https://www.python.org/ftp/python/3.14.3/python-3.14.3-embed-amd64.zip",
        install_flag = false,
        excu = nil,
        root = vmake_root .. "/tool/python_enbed",
        config = nil,
        cache = nil,
        version = "3.14.3",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = {
                vmake_root.."/tool/python_enbed",
                vmake_root.."/tool/python_enbed/Scripts"
            }
        },
    },
    -- java<通过内置命令下载>
    java = {
        url = "https://www.java.com/",
        download_url = "https://download.oracle.com/java/25/latest/jdk-25_windows-x64_bin.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/java/bin/java.exe",
        root = vmake_root .. "/tool/java",
        config = nil,
        cache = nil,
        version = "25",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/java/bin"},
    },
    -- rust<通过内置命令下载>
    rust = {
        url = "https://www.rust-lang.org/",
        download_url = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe",
        install_flag = false,
        excu = vmake_root .. "/tool/rust/cargo_home/bin/rustc.exe",
        root = vmake_root .. "/tool/rust",
        config = nil,
        cache = vmake_root .. "/tool/rust/cache",
        version = "1.93.1",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            cargo_home = vmake_root .. "/tool/rust/cargo_home",
            rustup_home = vmake_root .. "/tool/rust/rustup_home",
            path = vmake_root .. "/tool/rust/cargo_home/bin",
        },
    },
    -- golang<通过内置命令下载>
    golang = {
        url = "https://go.dev/",
        download_url = "https://go.dev/dl/go1.26.0.windows-amd64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/golang/bin/go.exe",
        root = vmake_root .. "/tool/golang",
        config = nil,
        cache = nil,
        version = "1.26.0",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = {
                vmake_root .. "/tool/golang/bin",
                vmake_root .. "/tool/golang/pkg/tool"
            }
        },
    },
    -- zig<通过内置命令下载>
    zig = {
        url = "https://ziglang.org/",
        download_url = "https://ziglang.org/builds/zig-x86_64-windows-0.16.0-dev.2565+684032671.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/zig/zig.exe",
        root = vmake_root .. "/tool/zig",
        config = nil,
        cache = nil,
        version = "0.16.0",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/zig"},
    },
    -- vlang<通过内置命令下载>
    vlang = {
        url = "https://github.com/vlang/v",
        download_url = "https://github.com/vlang/v/releases/download/weekly.2026.07/v_windows.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/vlang/v.exe",
        root = vmake_root .. "/tool/vlang",
        config = nil,
        cache = nil,
        version = "2026week07",
        active_flag = false,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {path = vmake_root .. "/tool/vlang"},
    },
};
-- 系统功能
-- (01)系统操作:路径操作,文件操作,字符串操作
-- (02)内置工具操作
vmake_sys = {
    -- system_assist辅助函数.系统类功能
    -- 彩色打印
    print_color = function(color, str, ...)
        local color_table = {
            -- 基础颜色
            black = "\x1b[30m",
            red = "\x1b[31m",
            green = "\x1b[32m",
            yellow = "\x1b[33m",
            blue = "\x1b[34m",
            magenta = "\x1b[35m",
            cyan = "\x1b[36m",
            white = "\x1b[37m",
            gray = "\x1b[90m",
            -- 亮色
            bright_red = "\x1b[91m",
            bright_green = "\x1b[92m",
            bright_yellow = "\x1b[93m",
            bright_blue = "\x1b[94m",
            bright_magenta = "\x1b[95m",
            bright_cyan = "\x1b[96m",
            bright_white = "\x1b[97m",
            -- 样式
            bold = "\x1b[1m",
            dim = "\x1b[2m",
            underline = "\x1b[4m",
            blink = "\x1b[5m",
            reverse = "\x1b[7m",
            -- 重置
            reset = "\x1b[0m",
            reset_bold = "\x1b[22m",
            reset_dim = "\x1b[22m",
            reset_underline = "\x1b[24m",
            reset_blink = "\x1b[25m",
            reset_reverse = "\x1b[27m",
        };
        local print_color = color;
        if color_table[print_color] == nil then print_color = "green"; end;
        local out_str = str;
        local arg_par = select("#",...);
        if arg_par>0 then
            for idx=1,arg_par do
                local arg_val = select(idx,...);
                out_str = out_str..tostring(arg_val);
            end
        end
        print(color_table[print_color]..out_str..color_table["reset"]);
    end;
    -- (01.01.)清空目标文件夹;先删除再创建
    clean_dir = function(dir_path)
        local del_cmd = "rmdir /s/q \""..dir_path.."\"";
        local create_cmd = "mkdir \""..dir_path.."\"";
        os.execute(del_cmd);
        os.execute(create_cmd);
        vmake_sys.print_color("cyan",string.format("\tdebug->location:<func>vmake_sys.clean_dir...%s",dir_path));
    end;
    -- (01.02.)检测目标路径是否存在
    detect_path = function(path)
        local cmd = string.format('if exist "%s" echo yes_exist', path);
        local handle = io.popen(cmd);
        local result = handle:read("*l"); -- 读取一行
        handle:close();
        return result=="yes_exist";
    end;
    -- (01.03.)移动文件夹到目标
    move_dir = function(source_dir, target_dir)
        local cmd = string.format('robocopy "%s" "%s" /e /move >nul', source_dir, target_dir);
        os.execute(cmd);
        vmake_sys.print_color("cyan","\tdebug->location:<func>vmake_sys.move_dir...",cmd);
    end;
    -- (01.04.)获取路径的最深层路径
    get_deep_path = function(path) -- 获取路径的深度, 文件夹下只有一个单独的文件, 没有其他文件或文件夹则继续向下遍历
        local list_dir = function(dir_path)
            local retval = {};
            local handle = io.popen(string.format("dir \"%s\" /a /b", dir_path));
            for line in handle:lines() do
                table.insert(retval, line);
            end;
            handle:close();
            return retval;
        end;
        local cur_path = path;
        local son_elemt = list_dir(cur_path);
        while #son_elemt==1 do 
            cur_path = cur_path.."/"..son_elemt[1];
            son_elemt = list_dir(cur_path);
        end;
        return cur_path;
    end;
    -- (01.05.)字符串切割, 并去除空部分
    split_str = function(str, delimiter)
        local retval = {};
        for match in (str..delimiter):gmatch("(.-)"..delimiter) do 
            if match~="" then table.insert(retval, match); end;
        end;
        return retval;
    end;
    cut_str = function(str, start_idx, end_idx) return str:sub(start_idx, end_idx); end;
    -- (01.06.)获取路径及其文件
    split_path = function(path)
        local retval = {};
        for idx=#path,1,-1 do
            local char = path:sub(idx, idx);
            if char=="\\" or char=="/" then
                local path_part = path:sub(1, idx-1);
                local file_part = path:sub(idx+1, #path);
                table.insert(retval, path_part);
                table.insert(retval, file_part);
                break;
            end
        end
        if #retval==0 then table.insert(retval, path); end
        return retval;
    end;
    -- (01.07.)获取文件名及其后缀名
    split_zip_filename = function(zip_filename)
        local zip_ext = {".zip",".7z",".tar",".gz",".rar",};
        local retval = {};
        for idx=1,#zip_ext do
            local zip_ext_name = zip_ext[idx];
            local find_idx = zip_filename:find(zip_ext_name);
            if find_idx~=nil then
                local zip_file_part = zip_filename:sub(1, find_idx-1);
                local zip_ext_part = zip_filename:sub(find_idx, #zip_filename);
                table.insert(retval, zip_file_part);
                table.insert(retval, zip_ext_part);
            end;
        end;
        if #retval==0 then table.insert(retval, zip_filename); end;
        return retval;
    end;
    -- vmake_assist辅助函数.vmake辅助类
    -- (02.01.)检测内置软件安装状态
    check_tool_install = function(tool_name) -- 检查软件安装状态
        for key,valu in pairs(vmake_tool) do    -- 判断没有内置的工具是否安装, 并更新软件安装状态
            local install_flag = false;
            if (vmake_sys.detect_path(valu.excu)==true) then install_flag=true; end;
            valu.install_flag = install_flag;
        end
    end;
    -- (02.02.)检测指定的命令软件, 并进行直接调用
    run_vmake_tool = function(tool_name, excu_name, cmd_arg)
        local cmd_install_flag = vmake_tool[tool_name].install_flag;
        local cmd_excu_path = vmake_tool[tool_name][excu_name];
        if cmd_install_flag==false then
            vmake_sys.print_color("red", string.format("err->location:<func>vmake_cmd.run_vmake_tool.%s...", tool_name));
            vmake_sys.print_color("red", string.format("err->'%s' is not installed!!!", tool_name));
            return false;
        end
        local cmd = string.format("%s %s", cmd_excu_path, cmd_arg);
        vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_sys.run_vmake_tool..."));
        vmake_sys.print_color("cyan", string.format("\tdebug->the cmd: %s", cmd));
        os.execute(cmd);
        return true;
    end;
    -- (02.03.)默认下载
    install_vmake_tool = function(tool_name)
        local down_url = vmake_tool[tool_name].download_url;
        vmake_sys.clean_dir(vmake_tool.a7z.cache);
        if type(down_url)=="string" then
            local down_file = vmake_sys.split_path(down_url)[2];
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            vmake_cmd.tool.aria2_inside(down_url, vmake_tool.aria2.cache, down_file);
            local down_file_name = vmake_sys.split_zip_filename(down_file)[1];
            local unzip_dir = vmake_tool.a7z.cache.."/"..down_file_name;
            local install_dir = vmake_tool[tool_name].root;
            local version_info = install_dir.."/v"..vmake_tool[tool_name].version;
            vmake_cmd.tool.a7z_inside(down_file_path, unzip_dir, "x");
            unzip_dir = vmake_sys.get_deep_path(unzip_dir);
            vmake_sys.clean_dir(install_dir);
            vmake_sys.move_dir(unzip_dir,install_dir);
            vmake_sys.clean_dir(version_info);
        end;
        if type(down_url)=="table" then
            local down_file = nil;
            local down_file_name = nil;
            local down_file_path = nil;
            local unzip_dir = nil;
            for idx=1,#down_url do  -- 下载
                local tmp_down_url = down_url[idx];
                local tmp_down_file = vmake_sys.split_path(down_url[idx])[2];
                local tmp_down_file_path = vmake_tool.aria2.cache.."/"..tmp_down_file;
                vmake_cmd.tool.aria2_inside(tmp_down_url, vmake_tool.aria2.cache, tmp_down_file);
                if idx==1 then
                    down_file = tmp_down_file;
                    down_file_name = vmake_sys.split_zip_filename(tmp_down_file)[1];
                    down_file_path = tmp_down_file_path;
                    unzip_dir = vmake_tool.a7z.cache.."/"..down_file_name;
                end;
            end;
            vmake_sys.clean_dir(vmake_tool.a7z.cache);
            vmake_cmd.tool.a7z_inside(down_file_path, unzip_dir, "x");  -- 解压
            unzip_dir = vmake_sys.get_deep_path(unzip_dir);   -- 获取深层解压路径
            local install_dir = vmake_tool[tool_name].root;
            local version_info = install_dir.."/v"..vmake_tool[tool_name].version;
            vmake_sys.clean_dir(install_dir);
            vmake_sys.move_dir(unzip_dir,install_dir);
            vmake_sys.clean_dir(version_info);
        end;
        vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_sys.install.%s...success installed!!!",tool_name));
    end;
    uninstall_vmake_tool = function(tool_name)
        vmake_sys.clean_dir(vmake_tool[tool_name].root);
        vmake_sys.print_color("green", string.format("info->location:<func>vmake_sys.uninstall.%s...success remove!!!",tool_name));
    end;
    -- (02.04.)设置环境变量
    set_vmake_tool_env_cat_table = function(tableA,tableB)
        vmake_sys.print_color("green","info->location:<func>vmake_sys.sys_env_table_cat...");
        local retval = {};
        if (type(tableA)~="table" or type(tableB)~="table") then vmake_sys.print_color("red","err->parameter tableA or tableB is not table!!!"); return retval; end;
        -- if (type(tableA)=="table" and #tableA==0) then return tableB; end;
        -- if (type(tableB)=="table" and #tableB==0) then return tableA; end;
        for kA,vA in pairs(tableA) do 
            if type(vA)=="string" then retval[kA] = {vA}; end;
            if type(vA)=="table" then retval[kA] = vA; end;
        end;
        -- 合并 tableB
        for kB,vB in pairs(tableB) do
            if retval[kB]==nil and type(vB)=="string" then retval[kB] = {vB}; goto next_loop; end;
            if retval[kB]==nil and type(vB)=="table" then retval[kB] = vB; goto next_loop; end;
            if type(retval[kB])=="string" and type(vB)=="string" then retval[kB] = {retval[kB], vB}; end;
            if type(retval[kB])=="string" and type(vB)=="table" then retval[kB] = {retval[kB]}; for i=1,#vB do table.insert(retval[kB], vB[i]); end; end;
            if type(retval[kB])=="table" and type(vB)=="string" then table.insert(retval[kB], vB); end;
            if type(retval[kB])=="table" and type(vB)=="table" then for i=1,#vB do table.insert(retval[kB], vB[i]); end; end;
            ::next_loop::;
        end;
        -- for k,v in pairs(retval) do for _,v1 in pairs(v) do print(k,"...",v1); end; end;
        vmake_sys.print_color("green","info->location:<func>vmake_sys.sys_env_table_cat...over");
        return retval;
    end;
    set_vmake_tool_env_gen_table  = function()
        vmake_sys.print_color("green", "info->location:<func>vmake_sys.set_vmake_tool_env_gen_table...");
        local retval = {};
        local tool_env = {};
        local sys_env = {};
        for k,v in pairs(vmake_tool) do
            local t_tool_env=vmake_tool[k].sys_env;
            if vmake_tool[k].active_flag==false then goto next_loop; end;
            if t_tool_env==nil then goto next_loop; end;
            for k1,v1 in pairs(t_tool_env) do
                if sys_env[k1]==nil then sys_env[k1]={}; end;
                if tool_env[k1]==nil and type(v1)=="string" then tool_env[k1] = {v1}; goto next_loop; end;
                if tool_env[k1]==nil and type(v1)=="table" then tool_env[k1] = v1; goto next_loop; end;
                if tool_env[k1]~=nil and type(v1)=="string" then table.insert(tool_env[k1],v1); goto next_loop; end;
                if tool_env[k1]~=nil and type(v1)=="table" then for _,v2 in pairs(v1) do table.insert(tool_env[k1],v2); end; goto next_loop; end;
                ::next_loop::
            end;
            ::next_loop::
        end;
        for k,v in pairs(sys_env) do 
            local t_sys_env = os.getenv(k);
            if t_sys_env==nil then t_sys_env = {}; end;
            if type(t_sys_env)=="string" then t_sys_env = vmake_sys.split_str(t_sys_env,";"); end;
            sys_env[k] = t_sys_env;
        end;
        retval = vmake_sys.set_vmake_tool_env_cat_table(tool_env,sys_env);
        -- for k,v in pairs(retval) do for _,v1 in pairs(v) do print(k,"...",v1); end; end;
        return retval;
            end;
            set_vmake_tool_env_gen_str  = function()
                vmake_sys.print_color("green", "info->location:<func>vmake_sys.set_vmake_tool_env_gen_str...");
        local retval = {};
        local t_table = vmake_sys.set_vmake_tool_env_gen_table();
        for k,v in pairs(t_table) do
            retval[k] = "";
            for i=1,#v do
                if i>=2 then retval[k] = retval[k]..";"..t_table[k][i]; end;
                if i==1 then retval[k] = t_table[k][i]; end;
            end;
        end;
        -- for k,v in pairs(retval) do print(k,"...",v);end;
        return retval;
            end;
            set_vmake_tool_env_gen_shell  = function()
                vmake_sys.print_color("green", "info->location:<func>vmake_sys.set_vmake_tool_env_gen_shell...");
        -- A.调用set_vmake_tool_env_gen_str生成环境变量key:value表
        local env_table = vmake_sys.set_vmake_tool_env_gen_str();
        -- for k,v in pairs(env_table) do print(k,"...",v);end;
        -- B.遍历变量表,写入cmd文件,只修改环境变量,不打开行的窗口
        local cmd_file = vmake_root .. "/script/vmake_shell.bat";
        local cmd_handle = io.open(cmd_file, "w");
        if cmd_handle == nil then
            vmake_sys.print_color("red", "err->failed to create cmd script: " .. cmd_file);
            return false;
        end;
        -- 写入CMD脚本头部
        cmd_handle:write("@echo off\n");
        cmd_handle:write("REM vmake environment variables setup script\n");
        cmd_handle:write("REM Auto-generated by vmake\n");
        cmd_handle:write("REM This script sets environment variables for the current session\n");
        cmd_handle:write("REM Usage: vmake_shell.bat\n\n");
        -- 收集所有环境变量键
        local env_keys = {};
        for env_name, env_value in pairs(env_table) do
            table.insert(env_keys, env_name);
        end;
        -- 对环境变量键进行字符串排序
        table.sort(env_keys);
        -- 按排序后的顺序写入环境变量，但不包括 PATH
        for i, env_name in ipairs(env_keys) do
            local env_name_lower = string.lower(env_name);
            if env_name_lower ~= "path" then
                cmd_handle:write(string.format("set \"%s=%s\"\n", env_name, env_table[env_name]));
            end;
        end;
        -- 将 PATH 放到最后
        for env_name, env_value in pairs(env_table) do
            local env_name_lower = string.lower(env_name);
            if env_name_lower == "path" then
                cmd_handle:write(string.format("set \"%s=%s\"\n", env_name, env_value));
            end;
        end;
        cmd_handle:write("\necho info->vmake environment variables set successfully\n");
        cmd_handle:write("\ncall cmd\n");
        cmd_handle:close();
        vmake_sys.print_color("cyan", "\tdebug->cmd script created: " .. cmd_file);
        return true;
    end;
    set_vmake_tool_env_gen_term = function(new_window)
        vmake_sys.print_color("green", "info->location:<func>vmake_sys.set_vmake_tool_env_gen_term...");
        -- A.调用set_vmake_tool_env_gen_shell重新生成shell文件
        local gen_result = vmake_sys.set_vmake_tool_env_gen_shell();
        if gen_result == false then
            vmake_sys.print_color("red", "err->failed to generate cmd script");
            return false;
        end;
        -- B.调用生成的cmd文件
        local cmd_file = vmake_root .. "/script/vmake_shell.bat";

        -- 如果没有指定 new_window 参数，默认为 true（兼容旧行为）
        if new_window == nil then new_window = true; end;

        if new_window == true then
            -- 打开新窗口（独立运行或用户明确要求）
            local cmd = string.format('cmd /k "%s"', cmd_file);
            vmake_sys.print_color("cyan", "\tdebug->launching new terminal with: " .. cmd);
            os.execute("start " .. cmd);
        else
            -- 在当前窗口执行（命令行调用）
            local cmd = string.format('cmd /k "%s"', cmd_file);
            vmake_sys.print_color("cyan", "\tdebug->executing in current terminal with: " .. cmd);
            os.execute(cmd);
        end;
        return true;
    end;
    -- (03.01.)生成luarocks的配置文件
    luarocks_gen_config = function()
        -- 根据vmake_root修改luarocks的配置文件,采取每次重新创建写入的方法,不存在文件则创建,存在文件则覆盖
        -- A.配置文件路径
        local luarocks_config_file_path = vmake_tool.lua.config;
        -- B.写入内容
        local current_time = os.date("%Y.%m.%d-%H:%M");
        local config_content = string.format([[
        -- lastEdit=>%s
        -- Auto-generated by vmake
        -- 指定配置文件路径
        -- 添加环境变量: luarocks_config = <config.lua>
        -- 默认安装树
        rocks_trees = {
        {
            name = "vgt",
            root = "%s",
        },
        }
        variables = {
            -- 指定lua路径
            LUA = "%s",
            -- luarocks安装配置
            LUA_BINDIR = "%s",
            LUA_INCDIR = "%s",
            LUA_LIBDIR = "%s",
        };
        ]], current_time, vmake_tool.lua.pkg_manager_root, vmake_tool.lua.excu, vmake_tool.lua.bin_root, vmake_tool.lua.include_root, vmake_tool.lua.lib_root);
        local config_handle = io.open(luarocks_config_file_path, "w");
        if config_handle == nil then
            vmake_sys.print_color("red", "err->failed to create luarocks config: " .. luarocks_config_file_path);
            return false;
        end;
        config_handle:write(config_content);
        config_handle:close();
        vmake_sys.print_color("cyan", "\tdebug->luarocks config created: " .. luarocks_config_file_path);
        return true;
    end;
};
-- 软件命令配置
vmake_cmd = {
    tool = {
        -- 开放命令
        lua = function(cmd_arg) vmake_sys.run_vmake_tool("lua", "excu", cmd_arg) end;
        luarocks = function(cmd_arg) vmake_sys.run_vmake_tool("lua", "pkg_manager_excu", cmd_arg) end;
        a7z = function(cmd_arg) vmake_sys.run_vmake_tool("a7z", "excu", cmd_arg) end;
        aria2 = function(cmd_arg) vmake_sys.run_vmake_tool("aria2", "excu", cmd_arg) end;
        pixi = function(cmd_arg) vmake_sys.run_vmake_tool("pixi", "excu", cmd_arg) end;
        -- 内置命令
        lua_inside = function(cmd_arg)
            local cmd = string.format("%s %s",vmake_tool.lua.excu,cmd_arg);
            vmake_sys.print_color("cyan","\tdebug->location<func>vmake_cmd.lua_inside..."..cmd);
            os.execute(cmd);
        end;
        luarocks_inside = function(cmd_arg)
            local cmd = string.format("%s %s --lua-dir=%s --tree=%s", vmake_tool.lua.pkg_manager_excu, cmd_arg, vmake_tool.lua.root,vmake_tool.lua.pkg_root)
            vmake_sys.print_color("cyan","\tdebug->location<func>vmake_cmd.luarocks_inside..."..cmd);
            os.execute(cmd);
        end;
        a7z_inside = function(source_file, dest_dir, unzip_flag) -- unzip_flag是a7z命令选项, "x"为解压到文件夹, "e"为直接解压到指定路径
            local cmd = string.format("%s %s %s -o%s", vmake_tool.a7z.excu, unzip_flag, source_file, dest_dir);
            vmake_sys.print_color("cyan","\tdebug->location<func>vmake_cmd.a7z_inside..."..cmd);
            os.execute(cmd);
            return true;
        end;
        aria2_inside = function(source_url, dest_dir, file_name)
            local cmd = string.format("%s %s --dir=%s --out=%s --allow-overwrite=true --auto-file-renaming=false", vmake_tool.aria2.excu, source_url, dest_dir, file_name);
            vmake_sys.print_color("cyan","\tdebug->location<func>vmake_cmd.aria2_inside..."..cmd);
            os.execute(cmd);
            return true;
        end;
        pixi_inside = function(cmd_arg)
            local cmd = string.format("cd /d %s && %s %s", vmake_root .. "/tool/pixi", vmake_tool.pixi.excu, cmd_arg);
            vmake_sys.print_color("cyan","\tdebug->location<func>vmake_cmd.pixi_inside..."..cmd);
            os.execute(cmd);
        end;
        -- 额外命令
        git = function(cmd_arg) vmake_sys.run_vmake_tool("git", "excu", cmd_arg) end;
        vcpkg = function(cmd_arg) vmake_sys.run_vmake_tool("vcpkg", "excu", cmd_arg) end;
        cmake = function(cmd_arg) vmake_sys.run_vmake_tool("cmake", "excu", cmd_arg) end;
        xmake = function(cmd_arg) vmake_sys.run_vmake_tool("xmake", "excu", cmd_arg) end;
        xrepo = function(cmd_arg) vmake_sys.run_vmake_tool("xmake", "pkg_manager_excu", cmd_arg) end;
        node = function(cmd_arg) vmake_sys.run_vmake_tool("nodejs", "excu", cmd_arg) end;
        npm = function() vmake_sys.run_vmake_tool("nodejs", "pkg_manager_excu", cmd_arg) end;
    },
    install = { -- 核心逻辑: 下载->解压->移动->创建版本信息
        git = function() vmake_sys.install_vmake_tool("git"); end;
        cmake = function() vmake_sys.install_vmake_tool("cmake"); end;
        xmake = function() vmake_sys.install_vmake_tool("xmake"); end;
        vcpkg = function()
            vmake_sys.install_vmake_tool("vcpkg");
            os.execute(string.format("%s/bootstrap-vcpkg.bat", vmake_tool.vcpkg.root)); -- 使用官方脚本安装
        end;
        mingw_w64 = function() vmake_sys.install_vmake_tool("mingw_w64"); end;
        mingw_llvm = function() vmake_sys.install_vmake_tool("mingw_llvm"); end;
        msvc_vsget = nil,
        msvc_llvm = function() vmake_sys.install_vmake_tool("msvc_llvm"); end;
        msvc_mini = function() vmake_sys.install_vmake_tool("msvc_mini"); end;
        nodejs = function() vmake_sys.install_vmake_tool("nodejs"); end;
        python = function() vmake_sys.install_vmake_tool("python"); end;
        python_enbed = function()
            -- 安装Python
            vmake_sys.install_vmake_tool("python_enbed");
            local python_root = vmake_tool.python_enbed.root;
            local python_exe = python_root .. "/python.exe";
            -- (01)修改vmake_root/tool/python/python3xx._pth文件的内容
            -- 修改#import site为import site以启用site模块
            local pth_file = nil;
            -- 查找._pth文件（Python embed版本会有python3xx._pth文件）
            local find_pth_cmd = string.format('dir "%s" /b /a *.pth', python_root);
            local handle = io.popen(find_pth_cmd);
            local pth_result = handle:read("*a");
            handle:close();
            -- 更精确地匹配._pth文件（排除其他.pth文件）
            if pth_result then
                for line in pth_result:gmatch("[^\r\n]+") do
                    if line:match("%._pth$") then
                        pth_file = python_root .. "/" .. line;
                        break;
                    end
                end
            end            -- 读取并修改._pth文件
            if pth_file then
                local pth_content = "";
                local pth_file_handle = io.open(pth_file, "r");
                if pth_file_handle then
                    pth_content = pth_file_handle:read("*a");
                    pth_file_handle:close();
                    -- 将#import site改为import site
                    pth_content = pth_content:gsub("#import site", "import site");
                    -- 写回文件
                    local pth_write_handle = io.open(pth_file, "w");
                    if pth_write_handle then
                        pth_write_handle:write(pth_content);
                        pth_write_handle:close();
                        vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.python...modified %s to enable site module", pth_file));
                    end
                end
            end
            -- (02)下载get-pip.py到aria2/cache
            local get_pip_url = "https://bootstrap.pypa.io/get-pip.py";
            local get_pip_file = "get-pip.py";
            local get_pip_cache = vmake_tool.aria2.cache;
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.python...downloading get-pip.py"));
            vmake_cmd.tool.aria2_inside(get_pip_url, get_pip_cache, get_pip_file);
            -- (03)使用python运行get-pip.py安装pip
            -- 设置环境变量以支持SSL
            local get_pip_path = get_pip_cache .. "/" .. get_pip_file;
            local install_cmd = string.format("set PYTHONPATH=%s && \"%s\" \"%s\" --no-warn-script-location", python_root, python_exe, get_pip_path);
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.python...installing pip..."));
            vmake_sys.print_color("cyan", string.format("\tdebug->installing cmd: %s", install_cmd));
            os.execute(install_cmd);
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.python...success installed pip!!!"));
        end;
        rust = function()
            -- (01)下载rust官方安装脚本
            local rustup_url = vmake_tool.rust.download_url;
            local rustup_file = "rustup-init.exe";
            local rustup_cache = vmake_tool.rust.cache;
            local rust_version_dir = vmake_tool.rust.root.."/v"..vmake_tool.rust.version;
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.rust...downloading rustup-init.exe"));
            vmake_sys.clean_dir(vmake_tool.rust.root);
            vmake_sys.clean_dir(rust_version_dir);
            vmake_cmd.tool.aria2_inside(rustup_url, rustup_cache, rustup_file);
            -- (02)设置rustup_home和cargo_home环境变量
            local rustup_home = vmake_tool.rust.sys_env.rustup_home;
            local cargo_home = vmake_tool.rust.sys_env.cargo_home;
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.rust...setting RUSTUP_HOME and CARGO_HOME"));
            -- (03)调用官方安装脚本, 人为选择安装
            local rustup_path = rustup_cache .. "/" .. rustup_file;
            -- 创建临时批处理文件以设置环境变量并启动安装程序
            local rustup_bat = rustup_cache .. "/rustup_install.bat";
            local bat_handle = io.open(rustup_bat, "w");
            if bat_handle then
                bat_handle:write(string.format("@echo off\r\n"));
                bat_handle:write(string.format("set RUSTUP_HOME=%s\r\n", rustup_home));
                bat_handle:write(string.format("set CARGO_HOME=%s\r\n", cargo_home));
                bat_handle:write(string.format("set PATH=%%CARGO_HOME%%;%%RUSTUP_HOME%%\\bin;%%PATH%%\r\n"));
                bat_handle:write(string.format("cd /d \"%s\"\r\n", rustup_cache));
                bat_handle:write(string.format("echo info->Installing Rust...\r\n"));
                bat_handle:write(string.format("echo info->RUSTUP_HOME=%%RUSTUP_HOME%%\r\n"));
                bat_handle:write(string.format("echo info->CARGO_HOME=%%CARGO_HOME%%\r\n"));
                bat_handle:write(string.format("\"%s\"\r\n", rustup_path));
                bat_handle:write(string.format("echo info->Rust installation completed!\r\n"));
                bat_handle:write(string.format("pause\r\n"));
                bat_handle:close();
            end
            -- 使用 start 命令在新窗口中运行批处理文件，支持用户交互
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.rust...launching rustup installer..."));
            vmake_sys.print_color("yellow", string.format("info->Please complete the Rust installation in the new window"));
            os.execute(string.format("start \"Rust Installer\" \"%s\"", rustup_bat));
            vmake_sys.print_color("cyan", string.format("\tdebug->location:<func>vmake_cmd.install.rust...rustup installer launched!!!"));
        end;
        golang = function() vmake_sys.install_vmake_tool("golang"); end;
        zig = function() vmake_sys.install_vmake_tool("zig"); end;
        vlang = function() vmake_sys.install_vmake_tool("vlang"); end;
    },
    uninstall = {
        git = function() vmake_sys.uninstall_vmake_tool("git"); end;
        cmake = function() vmake_sys.uninstall_vmake_tool("cmake"); end;
        xmake = function() vmake_sys.uninstall_vmake_tool("xmake"); end;
        vcpkg = function() vmake_sys.uninstall_vmake_tool("vcpkg"); end;
        mingw_w64 = function() vmake_sys.uninstall_vmake_tool("mingw_w64"); end;
        mingw_llvm = function() vmake_sys.uninstall_vmake_tool("mingw_llvm"); end;
        msvc_vsget = nil,
        msvc_llvm = function() vmake_sys.uninstall_vmake_tool("msvc_llvm"); end;
        msvc_mini = function() vmake_sys.uninstall_vmake_tool("msvc_mini"); end;
        nodejs = function() vmake_sys.uninstall_vmake_tool("nodejs"); end;
        python = function() vmake_sys.uninstall_vmake_tool("python"); end;
        python_enbed = function() vmake_sys.uninstall_vmake_tool("python_enbed"); end;
        rust =  function() vmake_sys.uninstall_vmake_tool("rust"); end;
        golang = function() vmake_sys.uninstall_vmake_tool("golang"); end;
        zig = function() vmake_sys.uninstall_vmake_tool("zig"); end;
        vlang = function() vmake_sys.uninstall_vmake_tool("vlang"); end;
    },
    creat_batch = function(term_cmd_conf)
        vmake_sys.print_color("green", "info->location:<func>vmake_cmd.creat_batch...");
        local script_dir = vmake_root .. "/script";
        local created_count = 0;
        for name, content in pairs(vmake_batch) do
            -- 如果指定了脚本名称，只创建指定的脚本
            if term_cmd_conf ~= nil and term_cmd_conf ~= "" and name ~= term_cmd_conf then
                goto continue_loop;
            end
            -- 根据 term_type 决定文件扩展名
            local file_ext = ".txt";  -- 默认创建 txt 文件
            if content.term_type == "cmd" then
                file_ext = ".bat";
            elseif content.term_type == "powershell" then
                file_ext = ".ps1";
            end
            local script_path = script_dir .. "/" .. name .. file_ext;
            local script_file = io.open(script_path, "w");
            if script_file == nil then
                vmake_sys.print_color("red", string.format("err->failed to create script: %s", script_path));
            else
                -- 写入脚本内容（从 batch_file 字段获取）
                for _, line in ipairs(content.batch_file) do
                    script_file:write(line .. "\n");
                end
                script_file:close();
                vmake_sys.print_color("cyan", string.format("\tdebug->created script: %s", script_path));
                created_count = created_count + 1;
            end
            ::continue_loop::
        end
        vmake_sys.print_color("green", string.format("info->created %d script(s) successfully!!!", created_count));
        return true;
    end,
    show_info = function()
        -- 使用彩色打印vmake_info中的信息（现代高对比度列表样式）
        -- 原始 vmake_info 字段白名单（只打印这些字段）
        local original_fields = {
            "name",
            "version",
            "author",
            "description",
            "license",
            "url"
        };
        -- 字段图标映射
        local field_icons = {
            name = "📌",
            version = "🏷️",
            author = "👤",
            description = "📝",
            license = "⚖️",
            url = "🔗"
        };
        -- 字段颜色映射（高对比度：key使用灰色，value使用亮色）
        local field_colors = {
            name = "92",
            version = "95",
            author = "96",
            description = "97",
            license = "93",
            url = "94"
        };
        -- 计算最大字段名长度用于对齐
        local max_field_len = 0;
        for _, field_name in ipairs(original_fields) do
            if #field_name > max_field_len then
                max_field_len = #field_name;
            end
        end;
        -- 标题
        print("\n\27[94m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\27[0m");
        print("  \27[93m📦 " .. (vmake_info.name or "VMake") .. " Information\27[0m");
        print("\27[94m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\27[0m\n");
        -- 只打印白名单中的字段
        for _, field_name in ipairs(original_fields) do
            local field_value = vmake_info[field_name];
            if field_value then
                local icon = field_icons[field_name] or "•";
                local color = field_colors[field_name] or "97";
                -- 计算key部分的对齐宽度
                local key_part = "  " .. icon .. " " .. field_name .. ":";
                local padding = string.rep(" ", max_field_len - #field_name);
                io.write("\27[90m" .. key_part .. padding .. " \27[0m");  -- 灰色key
                io.write("\27[" .. color .. "m" .. field_value .. "\27[0m\n");  -- 亮色value
            end;
        end;
        print("\27[94m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\27[0m");
    end;
    help = function()
        vmake_sys.print_color("green","info->location:<func>vmake_cmd.help...usage: vmake <command> [options]");
        vmake_sys.print_color("green",string.format("\t\t%s\t->\t%s","help","show help information"));
        vmake_sys.print_color("green",string.format("\t\t%s\t->\t%s","list","list all installed tools"));
        vmake_sys.print_color("green",string.format("\t\t%s\t->\t%s","setenv","set tools environment"));
        vmake_sys.print_color("green",string.format("\t\t%s\t->\t%s","install","install a software tool"));
        vmake_sys.print_color("green",string.format("\t\t%s\t->\t%s","uninstall","uninstall a software tool"));
        vmake_sys.print_color("green",string.format("\t\t%s\t->\t%s","creat_batch","create batch scripts from vmake_batch templates"));
    end;
    list = function()
        vmake_sys.print_color("green","info->location:<func>vmake_cmd.list...");
        vmake_sys.print_color("green","info->vmake_tool list:");
        vmake_sys.print_color("green","\t------------------------------");
        vmake_sys.print_color("green",string.format("\t%s\t->\t%s","tool_name","install_flag"));
        vmake_sys.print_color("green","\t------------------------------");
        for key,valu in pairs(vmake_tool) do    -- 遍历打印所有工具
            if valu.install_flag==true then vmake_sys.print_color("green",string.format("\t%s\t->\t%s",key,valu.install_flag)); end;
        end;
        vmake_sys.print_color("green","\t------------------------------");
    end;
    setenv = function(new_window) vmake_sys.set_vmake_tool_env_gen_term(new_window); end;
    update = nil,
    clean = function()
        vmake_sys.clean_dir(vmake_root.."/cache");
        vmake_sys.clean_dir(vmake_root.."/script");
        vmake_sys.clean_dir(vmake_tool.aria2.cache);
        vmake_sys.clean_dir(vmake_tool.a7z.cache);
    end;
    build = nil, 
    run = nil,
};
-- 脚本工具
-- 脚本格式参考: C:\sftw\tool\devTool\vgtBin\envSet_config.py 中的 env_cmd_dict
-- 使用方式: 运行 vmake creat_batch [script_name] 生成脚本
vmake_batch = {
    -- 代理设置脚本 - Clash
    proxy_clash = {
        term_type = "cmd",
        batch_file = {
            "@echo off",
            "set http_proxy=127.0.0.1:7890",
            "set https_proxy=127.0.0.1:7890",
            "echo info-}set the proxy to http://127.0.0.1:7890",
        },
    },
    -- 代理设置脚本 - V2Ray
    proxy_v2ray = {
        term_type = "cmd",
        batch_file = {
            "@echo off",
            "set http_proxy=127.0.0.1:7880",
            "set https_proxy=127.0.0.1:7880",
            "echo info-}set the proxy to http://127.0.0.1:7880",
        },
    },
    -- 取消代理设置
    unproxy = {
        term_type = "cmd",
        batch_file = {
            "@echo off",
            "set http_proxy=",
            "set https_proxy=",
            "echo info-}remove the proxy",
        },
    },
    -- 前缀工具脚本 - pixi
    prefix = {
        term_type = "cmd",
        batch_file = {
            "@echo off",
            "call pixi shell --manifest-path " .. vmake_root .. "/tool/pixi/pixi.toml",
            "echo info-}open prefix, toml<" .. vmake_root .. "/tool/pixi/pixi.toml>",
        },
    },
    -- Win11右键菜单恢复为Win10样式
    win11_right_click = {
        term_type = "cmd",
        batch_file = {
            "@echo off",
            "reg add \"HKCU/Software/Classes/CLSID/{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}/InprocServer32/\" /f /ve",
            "taskkill /f /im explorer.exe & start explorer.exe",
            "echo info-}change win11 right click menu to win10 style",
        },
    },
    -- VHD虚拟硬盘挂载工具
    vhd_mount = {
        term_type = "cmd",
        batch_file = {
            "@echo off",
            "echo.",
            "set /p vhd_path=info-}The vhd path:",
            "if not exist %vhd_path% ( echo error-}file note exist!!!&timeout 3 >nul&exit )",
            "set /p vhd_sign=info-}The vhd mount as[A-Z]:",
            "cmd /c \"echo SELECT VDISK FILE=%vhd_path% & echo ATTACH VDISK & echo sel par 1 & echo assign letter=%vhd_sign%\"|diskpart.exe",
            "echo.",
            "echo info-}The %vhd% is connecting...",
            "echo.",
            "echo info-}The %vhd% is ready!!!",
            "echo.",
            "echo info-}The operation over, Return to this window and press any key can pop the vhd!!!",
            "pause>nul",
            "cmd /c \"echo SELECT VDISK FILE=%vhd% & echo DETACH VDISK\"|diskpart.exe",
        },
    },
};

-- 02.解析软件配置文件
-- (01)解析传入的config_file文件, 若文件不存在则解析vmake_root/config.lua, 若还不存在则打印相关信息并返回错误值
-- (02)使用配置表更新默认表
-- 配置表: config.lua中的vmake_info, vmake_tool, vmake_sdk
-- 默认表:vmake.lua中的vmake_info, vmake_tool, vmake_sdk
-- 默认表中不存在的值严禁向默认表中添加
-- 遍历默认表中的所有可能得键值对, 有值在配置表中修改, 则更新默认表格
function analyze_config(config_file)
    -- (01)解析传入的config_file文件, 若文件不存在则解析vmake_root/config.lua, 若还不存在则打印相关信息并返回错误值
    if config_file == nil then
        config_file = vmake_root .. "/config.lua";
    end;
    local config_handle = io.open(config_file, "r");
    if config_handle == nil then
        vmake_sys.print_color("red", "err->config file not found: " .. config_file);
        vmake_sys.print_color("red", "err->configuration update stopped due to missing config file");
        return false;
    end;
    local config_content = config_handle:read("*a");
    config_handle:close();

    -- 使用临时环境加载配置文件
    local config_env = {};
    setmetatable(config_env, {__index = _G});
    local config_func, config_error = load(config_content, config_file, "t", config_env);
    if not config_func then
        vmake_sys.print_color("red", "err->failed to load config file: " .. tostring(config_error));
        return false;
    end;
    local config_status, load_error = pcall(config_func);
    if not config_status then
        vmake_sys.print_color("red", "err->failed to execute config file: " .. tostring(load_error));
        return false;
    end;
    vmake_sys.print_color("cyan", "\tdebug->loading config file: " .. config_file);

    -- (02)使用配置表更新默认表
    -- 配置表: config.lua中的vmake_info, vmake_tool, vmake_sdk
    -- 默认表:vmake.lua中的vmake_info, vmake_tool, vmake_sdk
    -- 默认表中不存在的值严禁向默认表中添加
    -- 遍历默认表中的所有可能得键值对, 有值在配置表中修改, 则更新默认表格

    -- 更新 vmake_info
    if config_env.vmake_info and type(config_env.vmake_info)=="table" and vmake_info and type(vmake_info)=="table" then
        for k,v in pairs(config_env.vmake_info) do
            if v and v~="" then
                vmake_info[k] = v;
            end;
        end;
        vmake_sys.print_color("cyan", "\tdebug->vmake_info updated from config.lua");
    end;

    -- 更新 vmake_tool（只更新已存在的工具属性，不允许添加新工具）
    if config_env.vmake_tool and type(config_env.vmake_tool)=="table" and vmake_tool and type(vmake_tool)=="table" then
        local updated_count = 0;
        local new_tool_count = 0;
        for tool_name, tool_config in pairs(config_env.vmake_tool) do
            if vmake_tool[tool_name] and type(tool_config)=="table" then
                for key, value in pairs(tool_config) do
                    if vmake_tool[tool_name][key]~=nil and value~=nil and value~="" then
                        -- sys_env 字段采用合并策略，其他字段采用覆盖策略
                        if key == "sys_env" and type(value)=="table" and type(vmake_tool[tool_name].sys_env)=="table" then
                            -- 合并 sys_env 表
                            for env_key, env_value in pairs(value) do
                                if type(env_value)=="string" then
                                    if vmake_tool[tool_name].sys_env[env_key]==nil then
                                        vmake_tool[tool_name].sys_env[env_key] = {env_value};
                                        updated_count = updated_count + 1;
                                    elseif type(vmake_tool[tool_name].sys_env[env_key])=="string" then
                                        vmake_tool[tool_name].sys_env[env_key] = {vmake_tool[tool_name].sys_env[env_key], env_value};
                                        updated_count = updated_count + 1;
                                    elseif type(vmake_tool[tool_name].sys_env[env_key])=="table" then
                                        table.insert(vmake_tool[tool_name].sys_env[env_key], env_value);
                                        updated_count = updated_count + 1;
                                    end;
                                elseif type(env_value)=="table" then
                                    if vmake_tool[tool_name].sys_env[env_key]==nil then
                                        vmake_tool[tool_name].sys_env[env_key] = env_value;
                                        updated_count = updated_count + 1;
                                    elseif type(vmake_tool[tool_name].sys_env[env_key])=="table" then
                                        for i=1,#env_value do
                                            table.insert(vmake_tool[tool_name].sys_env[env_key], env_value[i]);
                                        end;
                                        updated_count = updated_count + 1;
                                    end;
                                end;
                            end;
                        else
                            -- 其他字段采用覆盖策略
                            vmake_tool[tool_name][key] = value;
                            updated_count = updated_count + 1;
                        end;
                    end;
                end;
            else
                new_tool_count = new_tool_count + 1;
            end;
        end;
        if new_tool_count > 0 then
            vmake_sys.print_color("yellow", string.format("warn->skipped %d new tool(s) from config.lua (only existing tools can be updated)", new_tool_count));
        end;
        vmake_sys.print_color("cyan", string.format("\tdebug->vmake_tool updated from config.lua (%d property updates)", updated_count));
    end;

    -- (03)更新安装软件信息
    vmake_sys.check_tool_install();
    vmake_sys.print_color("cyan", "\tdebug->config analysis completed successfully");
    return true;
end

-- 03.解析命令行参数
-- (01)获取命令行参数
-- (02)命令匹配
function analyze_term()
    -- 命令实现函数
    function term_install(term_cmd_conf) vmake_cmd.install[term_cmd_conf](); end;
    function term_uninstall(term_cmd_conf) vmake_cmd.uninstall[term_cmd_conf](); end;
    vmake_sys.print_color("green","info->location:<func>analyze_term...analyze cmd start!!!");
    -- 获取全局变量下传递的命令行参数
    local term_cmd_type = arg[1];   -- 命令类型
    local term_cmd_conf = arg[2];   -- 命令参数
    for idx=3,#arg do term_cmd_conf = term_cmd_conf .. " " .. arg[idx]; end;
    if term_cmd_conf==nil then term_cmd_conf = ""; end;
    vmake_sys.print_color("magenta",string.format("\tdebug->location<func>analyze_term...term_cmd_type:'%s'\tterm_cmd_conf:'%s'",term_cmd_type,term_cmd_conf));
    -- 命令调用
    if term_cmd_type~=nil then
        -- 内置工具命令调用
        if (term_cmd_type=="lua") then
            vmake_cmd.tool.lua(term_cmd_conf);
        elseif (term_cmd_type=="luarocks") then
            vmake_cmd.tool.luarocks(term_cmd_conf);
        elseif (term_cmd_type=="aria2") then
            vmake_cmd.tool.aria2(term_cmd_conf);
        elseif (term_cmd_type=="a7z") then
            vmake_cmd.tool.a7z(term_cmd_conf);
        elseif (term_cmd_type=="pixi") then
            vmake_cmd.tool.pixi(term_cmd_conf);
        elseif (term_cmd_type=="prefix") then
            vmake_cmd.tool.pixi_inside(term_cmd_conf);
        -- 工具命令分析
        elseif (term_cmd_conf=="version") then
            vmake_cmd.show_info();
        elseif (term_cmd_type=="install") then
            term_install(term_cmd_conf);
            vmake_sys.check_tool_install();
        elseif (term_cmd_type=="uninstall") then
            term_uninstall(term_cmd_conf);
            vmake_sys.check_tool_install();
        elseif (term_cmd_type=="list") then
            vmake_cmd.list();
        elseif (term_cmd_type=="clean") then
            vmake_cmd.clean();
        elseif (term_cmd_type=="setEnv" or term_cmd_type=="setenv") then
            vmake_cmd.setenv(false);
        elseif (term_cmd_type=="help") then
            vmake_cmd.help(term_cmd_conf);
        elseif (term_cmd_type=="creat_batch" or term_cmd_type=="create_batch") then
            vmake_cmd.creat_batch(term_cmd_conf);
        -- 安装工具命令调用
        elseif (term_cmd_type=="git") then
            vmake_cmd.tool.git(term_cmd_conf);
        elseif (term_cmd_type=="vcpkg") then
            vmake_cmd.tool.vcpkg(term_cmd_conf);
        elseif (term_cmd_type=="cmake") then
            vmake_cmd.tool.cmake(term_cmd_conf);
        elseif (term_cmd_type=="xmake") then
            vmake_cmd.tool.xmake(term_cmd_conf);
        elseif (term_cmd_type=="xrepo") then
            vmake_cmd.tool.xrepo(term_cmd_conf);
        -- elseif (term_cmd_type=="mingw_w64") then
        --     vmake_cmd.tool.mingw_w64(term_cmd_conf);
        -- elseif (term_cmd_type=="mingw_llvm") then
        --     vmake_cmd.tool.mingw_llvm(term_cmd_conf);
        -- elseif (term_cmd_type=="msvc_vsget") then
        --     vmake_cmd.tool.msvc_vsget()
        -- 全部不匹配
        -- else
        --     vmake_cmd.help(term_cmd_conf);
        elseif (term_cmd_type=="node") then
            vmake_cmd.tool.node(term_cmd_conf);
        elseif (term_cmd_type=="npm") then
            vmake_cmd.tool.npm(term_cmd_conf);
        end
    end
-- 分析函数结束
end

-- 04.解析vmake_proj.lua配置文件
function analyze_proj()
    print("info->>>analyze proj<<");
end

-- 01.软件初始化配置
function vmake_init()
    vmake_cmd.show_info();
    vmake_sys.check_tool_install(); -- 检测内置软件安装状态
    -- vmake_cmd.clean();  -- 重置缓存状态
    vmake_cmd.creat_batch();   -- 创建系统脚本
    vmake_sys.set_vmake_tool_env_gen_shell();   -- 创建vmake_shell脚本
    vmake_sys.luarocks_gen_config(); -- 配置luarocks的配置文件
end

-- 05.软件结束配置
function vmake_over()
    print("info->end config");
end

function main()
    vmake_sys.print_color("blue","info->location:<func>main...init vmake!!!");
    -- 软件配置分析
    analyze_config(vmake_root.."/config.lua");
    -- 软件初始化
    vmake_init();
    -- 命令分析
    analyze_term();
    -- -- 项目配置分析
    -- analyze_proj();
    vmake_sys.print_color("blue","info->location:<func>main...over vmake!!!");
    local retval = nil;
    -- vmake_sys.set_vmake_tool_env_gen_str("vmake_tool");
    -- print("------------------------------------------");
    -- vmake_sys.set_vmake_tool_env_gen_term("vmake_tool");
    return retval;
end

main()  