-- lastEdit=>2026.01.27-21:16
-- lastEdit=>2026.01.24-24:00
-- lastEdit=>2026.01.08-22:56
-- creat: 2026.01.08
-- version: v.src#2026.01.24-22:46
--[[
    实现逻辑:
        01.初始化配置,读取<vmake_root/config.lua>,读取项目下的<vmake_proj_root/vmake_proj.lua>, 更新内置配置
        02.解析命令行参数, 获取命令行参数, 匹配命令, 调用对应函数
    核心功能结构:
        vmake_info: 软件信息
        vmake_tool: 软件配置
        system_func: 系统功能函数
        vmake_cmd: 软件命令配置
        vmake_sdk: 编译工具链配置
        vmake_pkg: 编译器工具链第三方包配置
    核心功能函数:
        01.vmake_init: 软件初始化配置
        02.analyze_config: 解析软件配置文件
        03.analyze_term: 解析命令行参数
        04.analyze_proj: 解析vmake_proj.lua配置文件
    辅助功能函数:
        A01.clean_dir: 清空目标文件夹
        A02.detect_path: 检测目标路径是否存在
        A03.move_dir: 移动文件夹到目标
]]
-- 软件根路径
vmake_root = io.popen("cd"):read("*a");
vmake_root = string.gsub(vmake_root, "\n", "");
vmake_root = string.gsub(vmake_root, "\\", "/");
lua_module_root = vmake_root .. "/tool/lua/luarocks/lib/lua/5.4/?.dll";
lua_share_root = vmake_root .. "/tool/lua/luarocks/share/lua/5.4/?.lua";
package.path = lua_share_root;  -- 引入第三方库, 源文件
package.cpath = lua_module_root;    -- 引入第三方库, 动态库
vmake_lua_module = {
    lfs = require("lfs"),
    penlight = require("pl.path"),
};
-- 软件信息
vmake_info = {
    name = "vmake",
    version = "v.src#2026.01.24-22:46",
    author = "vmake",
    description = "vmake is a make tool",
    license = "MIT",
    url = "https://github.com/vmake-dev/vmake",
};
-- 软件工具配置
-- (01)内置工具
-- (02)下载工具
vmake_tool = {
    -- vmake元素添加模板
    -- vmake_element_template = {
    --     url = nil,  -- 官网地址
    --     download_url = nil, -- 下载地址, 优先下载压缩包格式
    --     install_flag = false,   -- 是否安装
    --     excu = nil, -- 执行文件
    --     root = nil, -- 安装路径
    --     config = nil,   -- 配置文件
    --     cache = nil,    -- 缓存路径
    --     version = nil,  -- 版本
    -- },
    -- (01.01.)lua<内置>
    lua = {
        url = "https://www.lua.org/",
        download_url = "https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download",
        install_flag = true,
        excu = vmake_root .. "/tool/lua/bin/lua.exe",
        root = vmake_root .. "/tool/lua",
        config = nil,
        cache = nil,
        version = "5.4.2",
    },
    -- (01.02.)luarocks<内置>
    luarocks = {
        url = "https://luarocks.org/",
        download_url = "https://github.com/luarocks/luarocks/releases/download/v3.12.2/luarocks-3.12.2-windows-64.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/lua/luarocks/luarocks.exe",
        root = vmake_root .. "/tool/lua/luarocks",
        config = vmake_root .. "/tool/lua/luarocks/config.lua",
        cache = nil,
        version = "3.12.2",
    },
    -- (01.03.)pixi<内置>
    pixi = {
        url = "https://github.com/prefix-dev/pixi",
        download_url = "https://github.com/prefix-dev/pixi/releases/download/v0.63.2/pixi-x86_64-pc-windows-msvc.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/pixi/pixi.exe",
        root = vmake_root .. "/tool/pixi",
        config = nil,
        cache = vmake_root .. "/tool/pixi/cache",
        version = "0.63.2",
    },
    -- (01.04.)7z<内置>
    a7z = {
        url = "https://www.7-zip.org/",
        download_url = "https://www.7-zip.org/a/7z2301-extra.7z",
        install_flag = true,
        excu = vmake_root .. "/tool/a7z/7za.exe",
        root = vmake_root .. "/tool/a7z",
        config = nil,
        cache = vmake_root .. "/tool/a7z/cache",
        version = "2301",
    },
    -- (01.05.)aria2<内置>
    aria2 = {
        url = "https://aria2.github.io/",
        download_url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/aria2/aria2c.exe",
        root = vmake_root .. "/tool/aria2",
        config = nil,
        cache = vmake_root .. "/tool/aria2/cache",
        version = "1.37.0",
    },
    -- (02.01.)git<通过内置命令下载>
    git = {
        url = "https://git-scm.com/",
        download_url = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe",
        install_flag = false,
        excu = vmake_root .. "/tool/git/bin/git.exe",
        root = vmake_root .. "/tool/git",
        config = nil,
        cache = vmake_root .. "/tool/git/cache",
        version = "2.52.0",
    },
    -- (02.02.)cmake<通过内置命令下载>
    cmake = {
        url = "https://github.com/Kitware/CMake",
        download_url = "https://github.com/Kitware/CMake/releases/download/v4.2.2/cmake-4.2.2-windows-x86_64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/cmake/bin/cmake.exe",
        root = vmake_root .. "/tool/cmake",
        config = nil,
        cache = nil,
        version = "4.2.2",
    },
    -- (02.03.)xmake<通过内置命令下载>
    xmake = {
        url = "https://github.com/xmake-io/xmake",
        download_url = "https://github.com/xmake-io/xmake/releases/download/v3.0.6/xmake-v3.0.6.win64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/xmake/xmake.exe",
        xrepo = vmake_root .. "/tool/xmake/xrepo.bat",
        root = vmake_root .. "/tool/xmake",
        config = nil,
        cache = nil,
        version = "3.0.6",
    },
    -- (02.04.)vcpkg<通过内置命令下载>
    vcpkg = {
        url = "https://github.com/microsoft/vcpkg",
        download_url = "https://github.com/microsoft/vcpkg/archive/refs/tags/2026.01.16.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/vcpkg/vcpkg.exe",
        root = vmake_root .. "/tool/vcpkg",
        config = nil,
        cache = nil,
        version = "2026.01.16",
    },
    -- (02.05.)mingw_w64<通过内置命令下载>
    mingw_w64 = {
        url = "https://github.com/niXman/mingw-builds",
        download_url = "https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev0/x86_64-15.2.0-release-win32-seh-ucrt-rt_v13-rev0.7z",
        install_flag = false,
        excu = vmake_root .. "/tool/mingw_w64/bin/gcc.exe",
        root = vmake_root .. "/tool/mingw_w64",
        config = nil,
        cache = nil,
        version = "15.2.0",
    },
    -- (02.06.)mingw_llvm<通过内置命令下载>
    mingw_llvm = {
        url = "https://github.com/mstorsjo/llvm-mingw",
        download_url = "https://github.com/mstorsjo/llvm-mingw/releases/download/20251216/llvm-mingw-20251216-msvcrt-i686.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/mingw_llvm/bin/gcc.exe",
        root = vmake_root .. "/tool/mingw_llvm",
        config = nil,
        cache = nil,
        version = "15.2.0",
    },
    -- (02.07.)msvc_llvm<通过内置命令下载>
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
    }
    -- msvc_vsget<通过内置命令下载>
    -- golang<通过内置命令下载>
    -- rust<通过内置命令下载>
    -- nodejs<通过内置命令下载>
    -- python<通过内置命令下载>
    -- java<通过内置命令下载>
    -- dotnet<通过内置命令下载>
    
};
-- 系统功能
-- (01)系统操作:路径操作,文件操作,字符串操作
-- (02)内置工具操作
system_func = {
    -- >>>>>>>>>>>>>>>>>>>>>>>>-------------------------------<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    -- >>>>>>>>>>>>>>>>>>>>>>>>system_assist辅助函数.系统类功能<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    -- 彩色打印
    print_color = function(color, str, ...)
        local color_table = {
            red = "\x1b[31m",
            green = "\x1b[32m",
            yellow = "\x1b[33m",
            blue = "\x1b[34m",
            magenta = "\x1b[35m",
            cyan = "\x1b[36m",
            white = "\x1b[37m",
            reset = "\x1b[0m",
        };
        local print_color = color;
        if color_table[print_color] == nil then
            print_color = "green";
        end
        local out_str = str;
        local arg_par = select("#",...);
        if arg_par>0 then
            for idx=1,arg_par do
                local arg_val = select(idx,...);
                out_str = out_str..tostring(arg_val);
            end
        end
        print(color_table[print_color],out_str,color_table["reset"]);
    end;
    -- (01.01.)清空目标文件夹;先删除再创建
    clean_dir = function(dir_path)
        local del_cmd = "rmdir /s/q \""..dir_path.."\"";
        local create_cmd = "mkdir \""..dir_path.."\"";
        os.execute(del_cmd);
        os.execute(create_cmd);
        system_func.print_color("cyan",string.format("\tdebug->location:<func>system_func.clean_dir...%s",dir_path));
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
        system_func.print_color("cyan","\tdebug->location:<func>system_func.move_dir...",cmd);
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
    -- (01.05.)字符串切割
    split_str = function(str, delimiter)
        local retval = {};
        for match in (str..delimiter):gmatch("(.-)"..delimiter) do table.insert(retval, match); end;
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
    -- >>>>>>>>>>>>>>>>>>>>>>>>-------------------------------<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    -- >>>>>>>>>>>>>>>>>>>>>>>>vmake_assist辅助函数.vmake辅助类<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    -- (02.01.)检测内置软件安装状态
    check_tool_install = function(tool_name) -- 检查软件安装状态
        for key,valu in pairs(vmake_tool) do    -- 判断没有内置的工具是否安装, 并更新软件安装状态
            local install_flag = false;
            if (system_func.detect_path(valu.excu)==true) then install_flag=true; end;
            valu.install_flag = install_flag;
        end
    end;
    -- (02.02.)检测指定的命令软件, 并进行直接调用
    run_vmake_tool = function(tool_name, excu_name, cmd_arg)
        local cmd_install_flag = vmake_tool[tool_name].install_flag;
        local cmd_excu_path = vmake_tool[tool_name][excu_name];
        if cmd_install_flag==false then
            system_func.print_color("red", string.format("\t\terr->location:<func>vmake_cmd.tool.%s...", tool_name));
            system_func.print_color("red", string.format("\t\terr->'%s' is not installed, please run 'vmake install %s' to install it first!!!", tool_name, tool_name));
            return False;
        end
        local cmd = string.format("%s %s", cmd_excu_path, cmd_arg);
        system_func.print_color("green", string.format("\t\tdebug->location:<func>system_func.run_vmake_tool..."));
        system_func.print_color("green", string.format("\t\tdebug->the cmd: %s", cmd));
        os.execute(cmd);
        return True;
    end;
    -- (02.03.)默认下载
    install_vmake_tool = function(tool_name) 
        local down_url = vmake_tool[tool_name].download_url;
        system_func.clean_dir(vmake_tool.a7z.cache);
        if type(down_url)=="string" then
            local down_file = system_func.split_path(down_url)[2];
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            if system_func.detect_path(down_file_path)==false then vmake_cmd.tool.aria2_inside(down_url, vmake_tool.aria2.cache, down_file); end;
            local down_file_name = system_func.split_zip_filename(down_file)[1];
            local unzip_dir = vmake_tool.a7z.cache.."/"..down_file_name;
            local install_dir = vmake_tool[tool_name].root;
            local version_info = install_dir.."/v"..vmake_tool[tool_name].version;
            vmake_cmd.tool.a7z_inside(down_file_path, unzip_dir, "x");
            unzip_dir = system_func.get_deep_path(unzip_dir);
            system_func.clean_dir(install_dir);
            system_func.move_dir(unzip_dir,install_dir);
            system_func.clean_dir(version_info);
        end;
        if type(down_url)=="table" then
            local down_file = nil;
            local down_file_name = nil;
            local down_file_path = nil;
            local unzip_dir = nil;
            for idx=1,#down_url do  -- 下载
                local tmp_down_url = down_url[idx];
                local tmp_down_file = system_func.split_path(down_url[idx])[2];
                local tmp_down_file_path = vmake_tool.aria2.cache.."/"..tmp_down_file;
                if system_func.detect_path(tmp_down_file_path)==false then vmake_cmd.tool.aria2_inside(tmp_down_url, vmake_tool.aria2.cache, tmp_down_file); end;
                if idx==1 then
                    down_file = tmp_down_file;
                    down_file_name = system_func.split_zip_filename(tmp_down_file)[1];
                    down_file_path = tmp_down_file_path;
                    unzip_dir = vmake_tool.a7z.cache.."/"..down_file_name;
                end;
            end;
            system_func.clean_dir(vmake_tool.a7z.cache); 
            vmake_cmd.tool.a7z_inside(down_file_path, unzip_dir, "x");  -- 解压
            unzip_dir = system_func.get_deep_path(unzip_dir);   -- 获取深层解压路径
            local install_dir = vmake_tool[tool_name].root;
            local version_info = install_dir.."/v"..vmake_tool[tool_name].version;
            system_func.clean_dir(install_dir);
            system_func.move_dir(unzip_dir,install_dir);
            system_func.clean_dir(version_info);
        end;
        system_func.print_color("cyan", string.format("\tdebug->location:<func>system_func.install.%s...success installed!!!",tool_name));
    end;
    uninstall_vmake_tool = function(tool_name)
        system_func.clean_dir(vmake_tool[tool_name].root);
        system_func.print_color("cyan", string.format("\tinfo->location:<func>system_func.uninstall.%s...success remove!!!",tool_name));
    end;
    -- (02.04.)设置环境变量
    set_vmake_tool_env = function(tool_name)
        local env_str_cat = function(key,valu)
            local env_valu_append = valu;
            local env_valu_exist = os.getenv(key);
            if env_valu_exist~=nil then env_valu_exist = system_func.split_str(env_valu_exist,";"); end;
            if type(env_valu_append)=="string" then env_valu_append = {env_valu_append}; end; 
        end;
        local get_shell_env = function(tool_name)
            local retval = {};
            if tool_name=="vmake_sdk" then
                for k0,v0 in pairs(vmake_sdk) do 
                    local sdk = vmake_sdk[k0];
                    local sdk_env = sdk.sys_env;
                    if sdk_env~=nil then
                        for k,v in pairs(sdk_env) do -- 拼接所有变量到shell_env
                            if retval[k]==nil then retval[k] = {}; end;
                            if type(v)=="string" then table.insert(retval[k],v); end;
                            if type(v)=="table" then for k1,v1 in pairs(v) do table.insert(retval[k],v1); end; end;
                        end;
                    end;
                end;
                return retval;
            end;
            if vmake_sdk[tool_name]==nil then return nil; end;
            local sdk = vmake_sdk[tool_name];
            local sdk_env = sdk.sys_env;
            for k,v in pairs(sdk_env) do -- 拼接所有变量到shell_env
                if table[k]==nil then retval[k] = {}; end;
                if type(v)=="string" then table.insert(retval[k],v); end;
                if type(v)=="table" then for k1,v1 in pairs(v) do table.insert(retval[k],v1); end; end;
            end;
            return retval;
        end;
        local shell_env = get_shell_env(tool_name);
        for k,v in pairs(shell_env) do 
            for k1,v1 in pairs(v) do print(k,v1); end;
        end;
        system_func.print_color("green", "\t\tinfo->location:<func>system_func.set_vmake_tool_env...");
        system_func.print_color("green", string.format("\t\tdebug->set vmake tool '%s' env success!!!",tool_name));
        return shell_env;
    end;
}; 
-- 软件命令配置
vmake_cmd = {
    help = function()
        system_func.print_color("blue","\tinfo->location:<func>vmake_cmd.help...usage: vmake <command> [options]");
        system_func.print_color("green",string.format("\t\t%s\t->\t%s","help","show help information"));
        system_func.print_color("green",string.format("\t\t%s\t->\t%s","list","list all installed tools"));
        system_func.print_color("green",string.format("\t\t%s\t->\t%s","setenv","set tools environment"));
        system_func.print_color("green",string.format("\t\t%s\t->\t%s","install","install a software tool"));
        system_func.print_color("green",string.format("\t\t%s\t->\t%s","uninstall","uninstall a software tool"));
    end;
    list = function()
        system_func.print_color("green","\tinfo->location:<func>vmake_cmd.list...");
        system_func.print_color("green","\tinfo->vmake_tool list:");
        system_func.print_color("green","\t------------------------------");
        system_func.print_color("green",string.format("\t%s\t->\t%s","tool_name","install_flag"));
        system_func.print_color("green","\t------------------------------");
        for key,valu in pairs(vmake_tool) do    -- 遍历打印所有工具
            system_func.print_color("green",string.format("\t%s\t->\t%s",key,valu.install_flag));
        end;
        system_func.print_color("green","\t------------------------------");
    end;
    setenv = nil,
    tool = {
        -- 开放命令
        lua = function(cmd_arg) system_func.run_vmake_tool("lua", "excu", cmd_arg) end;
        luarocks = function(cmd_arg) system_func.run_vmake_tool("luarocks", "excu", cmd_arg) end;
        a7z = function(cmd_arg) system_func.run_vmake_tool("a7z", "excu", cmd_arg) end;
        aria2 = function(cmd_arg) system_func.run_vmake_tool("aria2", "excu", cmd_arg) end;
        pixi = function(cmd_arg) system_func.run_vmake_tool("pixi", "excu", cmd_arg) end;
        -- 内置命令
        luarocks_inside = function(cmd_arg)
            local cmd = string.format("%s %s --lua-dir=%s --tree=%s", vmake_tool.luarocks.excu, cmd_arg,vmake_tool.lua.root,vmake_tool.luarocks.root)
            system_func.print_color("cyan","\tdebug->location<func>vmake_cmd.luarocks_inside..."..cmd);
            os.execute(cmd);
        end;
        a7z_inside = function(source_file, dest_dir, unzip_flag) -- unzip_flag是a7z命令选项, "x"为解压到文件夹, "e"为直接解压到指定路径
            local cmd = string.format("%s %s %s -o%s", vmake_tool.a7z.excu, unzip_flag, source_file, dest_dir);
            system_func.print_color("cyan","\tdebug->location<func>vmake_cmd.a7z_inside..."..cmd);
            os.execute(cmd);
            return True;
        end;
        aria2_inside = function(source_url, dest_dir, file_name)
            local cmd = string.format("%s %s --dir=%s --out=%s --allow-overwrite=true --auto-file-renaming=false", vmake_tool.aria2.excu, source_url, dest_dir, file_name);
            system_func.print_color("cyan","\tdebug->location<func>vmake_cmd.aria2_inside..."..cmd);
            os.execute(cmd);
            return True;
        end;
        pixi_inside = function(cmd_arg)
            local cmd = string.format("%s %s --manifest-path=%s/pixi.toml", vmake_tool.pixi.excu, cmd_arg, vmake_tool.pixi.root);
            system_func.print_color("cyan","\tdebug->location<func>vmake_cmd.pixi_inside..."..cmd);
            os.execute(cmd);
        end;
        -- 额外命令
        git = function(cmd_arg) system_func.run_vmake_tool("git", "excu", cmd_arg) end;
        vcpkg = function(cmd_arg) system_func.run_vmake_tool("vcpkg", "excu", cmd_arg) end;
        cmake = function(cmd_arg) system_func.run_vmake_tool("cmake", "excu", cmd_arg) end;
        xmake = function(cmd_arg) system_func.run_vmake_tool("xmake", "excu", cmd_arg) end;
        xrepo = function(cmd_arg) system_func.run_vmake_tool("xmake", "xrepo", cmd_arg) end;
    },
    install = { -- 核心逻辑: 下载->解压->移动->创建版本信息
        pixi = function() system_func.install_vmake_tool("pixi"); end;
        git = function() system_func.install_vmake_tool("git"); end;
        cmake = function() system_func.install_vmake_tool("cmake"); end;
        xmake = function() system_func.install_vmake_tool("xmake"); end;
        vcpkg = function() 
            system_func.install_vmake_tool("vcpkg");
            os.execute(string.format("%s/bootstrap-vcpkg.bat", vmake_tool.vcpkg.root)); -- 使用官方脚本安装
        end;
        mingw_w64 = function() system_func.install_vmake_tool("mingw_w64"); end;
        mingw_llvm = function() system_func.install_vmake_tool("mingw_llvm"); end;
        msvc_vsget = nil,
        msvc_llvm = function() system_func.install_vmake_tool("msvc_llvm"); end;
    },
    uninstall = {
        pixi = function() system_func.uninstall_vmake_tool("pixi"); end;
        git = function() system_func.uninstall_vmake_tool("git"); end;
        cmake = function() system_func.uninstall_vmake_tool("cmake"); end;
        xmake = function() system_func.uninstall_vmake_tool("xmake"); end;
        vcpkg = function() system_func.uninstall_vmake_tool("vcpkg"); end;
        mingw_w64 = function() system_func.uninstall_vmake_tool("mingw_w64"); end;
        mingw_llvm = function() system_func.uninstall_vmake_tool("mingw_llvm"); end;
        msvc_vsget = nil,
        msvc_llvm = function() system_func.uninstall_vmake_tool("msvc_llvm"); end;
    },
    update = nil,
    clean = nil,
    build = nil, 
    run = nil,
    clean_cache = nil,
};
-- 编译工具链配置
vmake_sdk = {
    vmake_sdk_tmplate = { 
        excu = nil,
        version = nil,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = { -- 配置环境变量, key为环境变量名, value为环境变量值, value可以为字符串或字符串数组
            path = {"path1","path2",},
            k1 = {"k1v1","k2v2"},
            k2 = "k2v",
        },
    };
    lua = {
        excu = vmake_tool.lua.excu,
        version = vmake_tool.lua.version,
        pkg_root = vmake_tool.luarocks.root,
        pkg_manager_root = vmake_tool.luarocks.root,
        pkg_manager_excu = vmake_tool.luarocks.excu,
        bin_root = vmake_tool.lua.root.."/bin",
        include_root = vmake_tool.lua.root.."/include",
        lib_root = vmake_tool.lua.root.."/lib",
        share_root = nil,
        sys_env = { -- 配置环境变量, key为环境变量名, value为环境变量值, value可以为字符串或字符串数组
            path = {
                vmake_tool.lua.root.."/bin",
                vmake_tool.luarocks.root,
            },
            
        },
    };
    pixi = { 
        excu = vmake_tool.pixi.excu,
        version = vmake_tool.pixi.version,
        pkg_root = nil,
        pkg_manager_root = nil,
        pkg_manager_excu = nil,
        bin_root = nil,
        include_root = nil,
        lib_root = nil,
        share_root = nil,
        sys_env = {
            path = vmake_tool.pixi_root,
        },
    };
    mingw_w64 = {
        
    };
    mingw_llvm = {
        
    };
    msvc_vsget = {
        
    };
    msvc_llvm = {
        
    };
    vcpkg = { 
        
    };
    golang = {
        
    };
    rust = {
        
    };
    nodejs = {
        
    };
    python = {
        
    };
};
-- 编译器工具链第三方包配置
vmake_pkg = { 
};

-- 辅助函数B03.调用git下载到指定路径


-- 02.解析软件配置文件
function analyze_config()
    print("info->>>analyze config<<");
end

-- 03.解析命令行参数
function analyze_term()
    -- 命令实现函数
    function term_install(term_cmd_conf) -- 安装 
        if term_cmd_conf=="" then
            system_func.print_color("cyan","debug->>>install all<<<");
        elseif term_cmd_conf=="cmake" then
            vmake_cmd.install.cmake();
        elseif term_cmd_conf=="xmake" then
            vmake_cmd.install.xmake();
        elseif term_cmd_conf=="vcpkg" then
            vmake_cmd.install.vcpkg();
        elseif term_cmd_conf=="mingw_w64" then
            vmake_cmd.install.mingw_w64();
        elseif term_cmd_conf=="mingw_llvm" then
            vmake_cmd.install.mingw_llvm();
        -- elseif term_cmd_conf=="msvc_vsget" then
        elseif term_cmd_conf=="msvc_llvm" then
            vmake_cmd.install.msvc_llvm();
        end
    end
    function term_uninstall(term_cmd_conf) -- 卸载
        if term_cmd_conf=="git" then
            vmake_cmd.uninstall.git();
        elseif term_cmd_conf=="cmake" then
            vmake_cmd.uninstall.cmake();
        elseif term_cmd_conf=="xmake" then
            vmake_cmd.uninstall.xmake();
        elseif term_cmd_conf=="mingw_w64" then
            vmake_cmd.uninstall.mingw_w64();
        elseif term_cmd_conf=="mingw_llvm" then
            vmake_cmd.uninstall.mingw_llvm();
        -- elseif term_cmd_conf=="msvc_vsget" then
        elseif term_cmd_conf=="msvc_llvm" then
            vmake_cmd.uninstall.msvc_llvm();
        elseif term_cmd_conf=="vcpkg" then
            vmake_cmd.uninstall.vcpkg();
        end
    end

    system_func.print_color("green","\tinfo->location:<func>analyze_term...analyze cmd start!!!");
    -- (01)获取命令行参数
    -- (02)命令匹配
    -- 获取全局变量下传递的命令行参数
    local term_cmd_type = arg[1];   -- 命令类型
    local term_cmd_conf = arg[2];   -- 命令参数
    for idx=3,#arg do
        term_cmd_conf = term_cmd_conf .. " " .. arg[idx];
    end
    if term_cmd_conf==nil then  -- 空参数处理
        term_cmd_conf = "";
    end
    system_func.print_color("cyan",string.format("\tdebug->location<func>analyze_term...term_cmd_type:'%s'\tterm_cmd_conf:'%s'",term_cmd_type,term_cmd_conf));
    -- 命令调用
    if term_cmd_type~=nil then
        -- 内置工具
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
        -- 工具命令
        elseif (term_cmd_type=="install") then
            term_install(term_cmd_conf);
            system_func.check_tool_install();
        elseif (term_cmd_type=="uninstall") then
            term_uninstall(term_cmd_conf);
            system_func.check_tool_install();
        elseif (term_cmd_type=="list") then
            vmake_cmd.list();
        elseif (term_cmd_type=="setEnv" or term_cmd_type=="setenv") then
            vmake_cmd.setenv(term_cmd_conf);
        elseif (term_cmd_type=="help") then
            vmake_cmd.help(term_cmd_conf);
        -- 安装工具
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
    system_func.check_tool_install(); -- 检测内置软件安装状态
end

-- 05.软件结束配置
function vmake_over()
    print("info->end config");
end

function main()
    system_func.print_color("blue","info->location:<func>main...init vmake!!!");
    -- 软件初始化
    vmake_init();
    -- -- 软件配置分析 
    -- analyze_config();
    -- 命令分析
    analyze_term();
    -- -- 项目配置分析
    -- analyze_proj();
    system_func.print_color("blue","info->location:<func>main...over vmake!!!");
    -- system_func.set_vmake_tool_env("vmake_sdk");
    local retval = nil;
    return retval;
end

main()  