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
vmake_tool = {
    -- lua<内置>
    lua = {
        url = "https://www.lua.org/",
        download_url = "https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download",
        download_file = nil,
        install_flag = true,
        excu = vmake_root .. "/tool/lua/bin/lua.exe",
        root = vmake_root .. "/tool/lua",
        version = "5.4.2",
        include = vmake_root .. "/tool/lua/include",
        lib = vmake_root .. "/tool/lua/lib",
        bin = vmake_root .. "/tool/lua/bin",
        share = vmake_root .. "/tool/lua/share",
        package = vmake_root .. "/tool/lua/package",
        excu_arg = nil,
    },
    -- luarocks<内置>
    luarocks = {
        url = "https://luarocks.org/",
        download_url = "https://github.com/luarocks/luarocks/releases/download/v3.12.2/luarocks-3.12.2-windows-64.zip",
        download_file = nil,
        install_flag = true,
        excu = vmake_root .. "/tool/lua/luarocks/luarocks.exe",
        root = vmake_root .. "/tool/lua/luarocks",
        config = vmake_root .. "/tool/lua/luarocks/config.lua",
        version = nil,
        excu_arg = {
            string.format("--lua-dir=%s",vmake_root.."/tool/lua"),
            string.format("--tree=%s",vmake_root.."/tool/lua/luarocks"),
        },
    },
    -- 7z<内置>
    a7z = {
        url = "https://www.7-zip.org/",
        download_url = "https://www.7-zip.org/a/7z2301-extra.7z",
        download_file = nil,
        install_flag = true,
        excu = vmake_root .. "/tool/a7z/7za.exe",
        root = vmake_root .. "/tool/a7z",
        cache = vmake_root .. "/tool/a7z/cache",
        version = "2501",
        excu_arg = {
            string.format("-o%s",vmake_root.."/tool/a7z/cache"),
        },
    },
    -- aria2<内置>
    aria2 = {
        url = "https://aria2.github.io/",
        download_url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip",
        download_file = nil,
        install_flag = true,
        excu = vmake_root .. "/tool/aria2/aria2c.exe",
        root = vmake_root .. "/tool/aria2",
        cache = vmake_root .. "/tool/aria2/cache",
        version = "1.37.0",
        excu_arg = {
            string.format("--dir=%s",vmake_root.."/tool/aria2/cache"),
            "--allow-overwrite=true --auto-file-renaming=false",
        },
    },
    -- git<通过内置命令下载>
    git = {
        url = "https://git-scm.com/",
        download_url = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe",
        download_file = "PortableGit-2.52.0-64-bit.7z.exe",
        install_flag = false,
        excu = vmake_root .. "/tool/git/bin/git.exe",
        root = vmake_root .. "/tool/git",
        cache = vmake_root .. "/tool/git/cache",
        version = "2.52.0",
        excu_arg = nil,
    },
    -- vcpkg<通过内置命令下载>
    vcpkg = {
        url = "https://github.com/microsoft/vcpkg",
        download_url = "https://github.com/microsoft/vcpkg/archive/refs/tags/2026.01.16.zip",
        download_file = "vcpkg-2026.01.16.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/vcpkg/vcpkg.exe",
        root = vmake_root .. "/tool/vcpkg",
        version = "2026.01.16",
        excu_arg = nil,
    },
    -- cmake<通过内置命令下载>
    cmake = {
        url = "https://github.com/Kitware/CMake",
        download_url = "https://github.com/Kitware/CMake/releases/download/v4.2.2/cmake-4.2.2-windows-x86_64.zip",
        download_file = "cmake-4.2.2-windows-x86_64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/cmake/bin/cmake.exe",
        root = vmake_root .. "/tool/cmake",
        version = "4.2.2",
        excu_arg = nil,
    },
    -- xmake<通过内置命令下载>
    xmake = {
        url = "https://github.com/xmake-io/xmake",
        download_url = "https://github.com/xmake-io/xmake/releases/download/v3.0.6/xmake-v3.0.6.win64.zip",
        download_file = "xmake-v3.0.6.win64.zip",
        install_flag = false,
        excu = vmake_root .. "/tool/xmake/xmake.exe",
        root = vmake_root .. "/tool/xmake",
        version = "3.0.6",
        excu_arg = nil,
        xrepo = vmake_root .. "/tool/xmake/xrepo.bat",
    }
    -- mingw_w64<通过内置命令下载>
    -- mingw_llvm<通过内置命令下载>
    -- msvc_llvm<通过内置命令下载>
    -- msvc_vsget<通过内置命令下载>
    -- golang<通过内置命令下载>
    -- rust<通过内置命令下载>
    -- nodejs<通过内置命令下载>
    -- python<通过内置命令下载>
    -- java<通过内置命令下载>
    -- dotnet<通过内置命令下载>
    -- vmake元素添加模板
};
-- 系统功能
system_func = {
    -- 辅助函数A01.清空目标文件夹
    clean_dir = function(dir_path)
        os.execute("rmdir /s/q \""..dir_path.."\"");    -- 删除目标文件夹
        os.execute("mkdir \""..dir_path.."\""); -- 创建目标文件夹
    end;
    -- 辅助函数A02.检测目标路径是否存在
    detect_path = function(path)
        local cmd = string.format('if exist "%s" echo yes_exist', path);
        local handle = io.popen(cmd);
        local result = handle:read("*l"); -- 读取一行
        handle:close();
        return result=="yes_exist";
    end;
    -- 辅助函数A03.移动文件夹到目标
    move_dir = function(source_dir, target_dir)
        local cmd = string.format('robocopy "%s" "%s" /e /move >nul', source_dir, target_dir);
        os.execute(cmd);
        print("\t\tdebug->function: move_dir...arg:",cmd);
    end;
    -- 辅助函数A04.void
    -- 辅助函数.检测内置软件安装状态
    check_tool_install = function(tool_name) -- 检查软件安装状态
        for key,valu in pairs(vmake_tool) do    -- 判断没有内置的工具是否安装, 并更新软件安装状态
            if (valu.install_flag == false and system_func.detect_path(valu.excu)==true) then
                valu.install_flag = true;
            end
        end
    end;
    -- 辅助函数.打印颜色
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
};
-- 软件命令配置
vmake_cmd = {
    help = function()
        system_func.print_color("cyan","\tinfo->location:<func>vmake_cmd.help...");
        system_func.print_color("cyan","\tinfo->usage: vmake <command> [options]");
        system_func.print_color("cyan","\tinfo->commands:");
        system_func.print_color("green",string.format("\t\t%s\t%s","help","show help information"));
        system_func.print_color("green",string.format("\t\t%s\t%s","list","list all installed tools"));
        system_func.print_color("green",string.format("\t\t%s\t%s","setenv","set tools environment"));
        system_func.print_color("green",string.format("\t\t%s\t%s","install","install a software tool"));
        system_func.print_color("green",string.format("\t\t%s\t%s","uninstall","uninstall a software tool"));
    end;
    list = function()
        system_func.print_color("cyan","\tinfo->location:<func>vmake_cmd.list...");
        system_func.print_color("cyan","\tinfo->vmake_tool list:");
        system_func.print_color("cyan","\t\t------------------------------");
        system_func.print_color("cyan",string.format("\t\t%s\t%s","tool_name","install_flag"));
        system_func.print_color("cyan","\t\t------------------------------");
        for key,valu in pairs(vmake_tool) do    -- 遍历打印所有工具
            system_func.print_color("cyan",string.format("\t\t%s\t%s",key,valu.install_flag));
        end
        system_func.print_color("cyan","\t\t------------------------------");
    end;
    setenv = nil,
    tool = {
        lua = function(cmd_arg) os.execute(string.format("%s %s", vmake_tool.lua.excu, cmd_arg)) end;
        luarocks = function(cmd_arg) os.execute(string.format("%s %s", vmake_tool.luarocks.excu, cmd_arg)) end;
        a7z = function(cmd_arg) os.execute(string.format("%s %s", vmake_tool.a7z.excu, cmd_arg)) end;
        aria2 = function(cmd_arg) os.execute(string.format("%s %s", vmake_tool.aria2.excu, cmd_arg)) end;
        -- 调用a7z解压到指定路径
        a7z_inside = function(source_file, dest_dir, unzip_flag) -- unzip_flag是a7z命令选项, "x"为解压到文件夹, "e"为直接解压到指定路径
            local cmd = string.format("%s %s %s -o%s", vmake_tool.a7z.excu, unzip_flag, source_file, dest_dir);
            os.execute(cmd);
            return True;
        end;
        -- 调用aria2下载到指定路径, 覆盖下载
        aria2_inside = function(source_url, dest_dir)
            local cmd = string.format("%s %s --dir=%s --allow-overwrite=true --auto-file-renaming=false", vmake_tool.aria2.excu, source_url, dest_dir);
            os.execute(cmd);
            return True;
        end;
        -- git命令
        git = function(cmd_arg) 
            if vmake_tool.git.install_flag==false then
                system_func.print_color("red", "\t\terr->location:<func>vmake_cmd.tool.git...");
                system_func.print_color("red", "\t\terr->git is not installed, please run 'vmake install git' to install it first!!!");
                return False;
            end
            os.execute(string.format("%s %s", vmake_tool.git.excu, cmd_arg));
            return True;
        end;
        -- vcpkg命令
        vcpkg = function(cmd_arg) 
            if vmake_tool.vcpkg.install_flag==false then
                system_func.print_color("red", "\t\terr->location:<func>vmake_cmd.tool.vcpkg...");
                system_func.print_color("red", "\t\terr->vcpkg is not installed, please run 'vmake install vcpkg' to install it first!!!");
                return False;
            end
            os.execute(string.format("%s %s", vmake_tool.vcpkg.excu, cmd_arg));
            return True;
        end;
        cmake = function(cmd_arg) 
            if vmake_tool.cmake.install_flag==false then
                system_func.print_color("red", "\t\terr->location:<func>vmake_cmd.tool.cmake...");
                system_func.print_color("red", "\t\terr->cmake is not installed, please run 'vmake install cmake' to install it first!!!");
                return False;
            end
            os.execute(string.format("%s %s", vmake_tool.cmake.excu, cmd_arg));
            return True;
        end;
        xmake = function(cmd_arg) 
            if vmake_tool.xmake.install_flag==false then
                system_func.print_color("red", "\t\terr->location:<func>vmake_cmd.tool.xmake...");
                system_func.print_color("red", "\t\terr->xmake is not installed, please run 'vmake install xmake' to install it first!!!");
                return False;
            end
            os.execute(string.format("%s %s", vmake_tool.xmake.excu, cmd_arg));
            return True;
        end;
        xrepo = function(cmd_arg) 
            if vmake_tool.xmake.install_flag==false then
                system_func.print_color("red", "\t\terr->location:<func>vmake_cmd.tool.xrepo...");
                system_func.print_color("red", "\t\terr->xmake is not installed, please run 'vmake install xmake' to install it first!!!");
                return False;
            end
            os.execute(string.format("%s %s", vmake_tool.xmake.xrepo, cmd_arg));
            return True;
        end;
    },
    install = {
        git = function()
            local down_file = vmake_tool.git.download_file; 
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            local down_url = vmake_tool.git.download_url;
            local down_dir = vmake_tool.aria2.cache;
            local unzip_dir = vmake_tool.a7z.cache;
            local middle_root_dir = vmake_tool.a7z.cache.."/git";
            local install_dir = vmake_tool.git.root;
            system_func.clean_dir(install_dir);     -- 删除git
            system_func.clean_dir(middle_root_dir);   -- 删除解压中间文件夹
            vmake_cmd.tool.aria2_inside(down_url, down_dir);
            vmake_cmd.tool.a7z_inside(down_file_path, middle_root_dir, "x");
            system_func.move_dir(middle_root_dir, install_dir);
            system_func.print_color("green", "\t\tinfo-><location:<func>vmake_cmd.install.git...");
            system_func.print_color("green", "\t\tdebug->the git install success!!!");
        end;
        cmake = function() 
            local down_file = vmake_tool.cmake.download_file;
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            local down_url = vmake_tool.cmake.download_url;
            local down_dir = vmake_tool.aria2.cache;
            local unzip_dir = vmake_tool.a7z.cache;
            local middle_root_dir = vmake_tool.a7z.cache.."/"..string.sub(vmake_tool.cmake.download_file,1,-5);  -- 解压后的根路径
            local install_dir = vmake_tool.cmake.root;
            system_func.clean_dir(install_dir);   -- 删除cmake
            system_func.clean_dir(middle_root_dir); -- 删除解压中间文件夹
            vmake_cmd.tool.aria2_inside(down_url, down_dir);    -- 下载cmake
            vmake_cmd.tool.a7z_inside(down_file_path, middle_root_dir, "x");    -- 解压cmake
            system_func.move_dir(middle_root_dir.."/"..string.sub(vmake_tool.cmake.download_file,1,-5), install_dir);   -- 移动cmake
            system_func.print_color("green", "\t\tinfo-><location:<func>vmake_cmd.install.cmake...");
            system_func.print_color("green", "\t\tdebug->the cmake install success!!!");        
        end;
        xmake = function() 
            local down_file = vmake_tool.xmake.download_file;
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            local down_url = vmake_tool.xmake.download_url;
            local down_dir = vmake_tool.aria2.cache;
            local unzip_dir = vmake_tool.a7z.cache;
            local middle_root_dir = vmake_tool.a7z.cache.."/"..string.sub(vmake_tool.xmake.download_file,1,-5);  -- 解压后的根路径
            local install_dir = vmake_tool.xmake.root;
            system_func.clean_dir(install_dir);   -- 删除xmake
            system_func.clean_dir(middle_root_dir); -- 删除解压中间文件夹
            vmake_cmd.tool.aria2_inside(down_url, down_dir);    -- 下载xmake
            vmake_cmd.tool.a7z_inside(down_file_path, middle_root_dir, "x");
            system_func.move_dir(middle_root_dir.."/xmake", install_dir);   -- 移动xmake
            system_func.print_color("green", "\t\tinfo->location:<func>vmake_cmd.install.xmake...");
            system_func.print_color("green", "\t\tdebug->the xmake install success!!!");
        end;
        mingw_w64 = nil,
        mingw_llvm = nil,
        msvc_vsget = nil,
        msvc_llvm = nil,
        vcpkg = function() 
            local down_file = vmake_tool.vcpkg.download_file;
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            local down_url = vmake_tool.vcpkg.download_url;
            local down_dir = vmake_tool.aria2.cache;
            local unzip_dir = vmake_tool.a7z.cache;
            local middle_root_dir = vmake_tool.a7z.cache.."/"..string.sub(vmake_tool.vcpkg.download_file,1,-5);  -- 解压后的根路径
            local install_dir = vmake_tool.vcpkg.root;
            system_func.clean_dir(install_dir);   -- 删除vcpkg
            system_func.clean_dir(middle_root_dir);   -- 删除解压中间文件夹
            vmake_cmd.tool.aria2_inside(down_url, down_dir);   -- 下载vcpkg
            vmake_cmd.tool.a7z_inside(down_file_path, middle_root_dir, "x");    -- 解压vcpkg
            system_func.move_dir(middle_root_dir.."/"..string.sub(vmake_tool.vcpkg.download_file,1,-5), install_dir);   -- 移动vcpkg
            os.execute(string.format("%s/bootstrap-vcpkg.bat", vmake_tool.vcpkg.root)); -- 使用官方脚本安装
            system_func.print_color("green", "\t\tinfo-><location:<func>vmake_cmd.install.vcpkg...>");
            system_func.print_color("green", "\t\tdebug->the vcpkg install success!!!");
        end;
    },
    uninstall = {
        git = function()
            system_func.clean_dir(vmake_tool.git.root);     -- 删除git
            system_func.print_color("red", "\t\tinfo-><location:<func>vmake_cmd.install.git...");
            system_func.print_color("red", "\t\tdebug->the git remove success!!!");
        end;
        cmake = nil,
        make = nil,
        mingw_w64 = nil,
        mingw_llvm = nil,
        msvc_vsget = nil,
        msvc_llvm = nil,
        vcpkg = function() 
            system_func.clean_dir(vmake_tool.vcpkg.root);   -- 删除vcpkg
            system_func.print_color("red", "\t\tinfo-><location:<func>vmake_cmd.install.vcpkg...");
            system_func.print_color("red", "\t\tdebug->the vcpkg remove success!!!");
        end;
    },
    update = nil,
    clean = nil,
    build = nil,
    run = nil,
    clean_cache = nil,
    
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
        if term_cmd_conf=="git" then
            vmake_cmd.install.git();
        elseif term_cmd_conf=="cmake" then
            vmake_cmd.install.cmake();
        elseif term_cmd_conf=="xmake" then
            vmake_cmd.install.xmake();
        -- elseif term_cmd_conf=="mingw_w64" then
        -- elseif term_cmd_conf=="mingw_llvm" then
        -- elseif term_cmd_conf=="msvc_vsget" then
        -- elseif term_cmd_conf=="msvc_llvm" then
        elseif term_cmd_conf=="vcpkg" then
            vmake_cmd.install.vcpkg();
        end
    end
    function term_uninstall(term_cmd_conf) -- 卸载
        if term_cmd_conf=="git" then
            vmake_cmd.uninstall.git();
        elseif term_cmd_conf=="cmake" then
            vmake_cmd.uninstall.cmake();
        elseif term_cmd_conf=="xmake" then
            vmake_cmd.uninstall.xmake();
        -- elseif term_cmd_conf=="mingw_w64" then
        -- elseif term_cmd_conf=="mingw_llvm" then
        -- elseif term_cmd_conf=="msvc_vsget" then
        -- elseif term_cmd_conf=="msvc_llvm" then
        elseif term_cmd_conf=="vcpkg" then
            vmake_cmd.uninstall.vcpkg();
        end
    end

    system_func.print_color("green","\tinfo->location:<func>analyze_term...");
    system_func.print_color("green","\tinfo->analyze cmd start!!!");
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
    system_func.print_color("red","\tdebug->cmd type:",term_cmd_type);
    system_func.print_color("red","\tdebug->cmd conf:",term_cmd_conf);
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
        -- 全部不匹配
        else
            vmake_cmd.help(term_cmd_conf);
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
    system_func.print_color("blue","info->location:<func>main...");
    system_func.print_color("blue","info->init vmake!!!");
    -- 软件初始化
    vmake_init();
    -- -- 软件配置分析 
    -- analyze_config();
    -- 命令分析
    analyze_term();
    -- -- 项目配置分析
    -- analyze_proj();
    system_func.print_color("blue","info->location:<func>main...");
    system_func.print_color("blue","info->over vmake!!!");
    local retval = nil;
    return retval;
end

main() 