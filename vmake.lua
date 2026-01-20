-- lastEdit=>2026.01.08-22:56
-- creat: 2026.01.08
--[[
    实现逻辑:
        01.初始化配置,读取<vmake_root/config.lua>,读取项目下的<vmake_proj_root/vmake_proj.lua>, 更新内置配置
        02.解析命令行参数, 获取命令行参数, 匹配命令, 调用对应函数
    核心功能结构:
        vmake_info: 软件信息
        vmake_tool: 软件配置
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
-- 辅助函数A01.清空目标文件夹
function clean_dir(dir_path)
    os.execute("rmdir /s/q \""..dir_path.."\"");    -- 删除目标文件夹
    os.execute("mkdir \""..dir_path.."\""); -- 创建目标文件夹
end

-- 辅助函数A02.检测目标路径是否存在
function detect_path(path)
    local cmd = string.format('if exist "%s" echo yes_exist', path);
    local handle = io.popen(cmd);
    local result = handle:read("*l"); -- 读取一行
    handle:close();
    return result=="yes_exist";
end

-- 辅助函数A03.移动文件夹到目标
function move_dir(source_dir, target_dir)
    local cmd = string.format('move "%s" "%s"', source_dir, target_dir);
    os.execute(cmd);
    print("\t\tdebug->function: move_dir...arg:",cmd);
end

-- 辅助函数A04.调用系统命令
function system_execute(cmd)
    os.execute(cmd);
    print("\tdebug->term_os_execute cmd:",cmd);
end

-- 辅助函数B01.调用内部vmake_tool表格中的命令
function default_vmake_tool(term_cmd, term_cmd_conf)  
    local cmd = vmake_tool[term_cmd].excu;
    cmd = string.format("%s %s", cmd, term_cmd_conf);
    for idx=1,#vmake_tool[term_cmd].excu_arg do
        cmd = string.format("%s %s",cmd,vmake_tool[term_cmd].excu_arg[idx]);
    end
    os.execute(cmd);
    print("\t\tdebug->term_vmake_tool cmd:",cmd);
end

-- 辅助函数B02.调用a7z解压到指定路径
function a7z(source_file, dest_dir)
    local cmd = string.format("%s x %s -o%s", vmake_tool.a7z.excu, source_file,dest_dir);
    os.execute(cmd);
end

-- 辅助函数B03.调用aria2下载到指定路径, 覆盖下载
function aria2(source_url, dest_dir)
    local cmd = string.format("%s %s --dir=%s --allow-overwrite=true --auto-file-renaming=false", vmake_tool.aria2.excu, source_url, dest_dir);
    os.execute(cmd);
end

-- 辅助函数A07.调用git下载到指定路径


-- 02.解析软件配置文件
function analyze_config()
    print("info->>>analyze config<<");
end

-- 03.解析命令行参数
function analyze_term()
    -- 命令实现函数
    function term_help(term_cmd, term_cmd_conf) -- 帮助信息
        print("\t\tsig->function: term_help");
        print(vmake_info);
    end
    function term_list(term_cmd, term_cmd_conf) -- 打印工具安装信息
       print("\t\tsig->function: term_list");
    end
    function term_setEnv(term_cmd, term_cmd_conf)   -- 将工具添加到环境变量
        print("\t\tsig->function: term_setEnv");
    end
    function term_install(term_cmd, term_cmd_conf) -- 安装
        print("\t\tsig->function: term_install");
        if term_cmd_conf=="git" then
            local down_file = vmake_tool.git.download_file;
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            local down_url = vmake_tool.git.download_url;
            local down_dir = vmake_tool.aria2.cache;
            local unzip_dir = vmake_tool.a7z.cache;
            local middle_root_dir = vmake_tool.a7z.cache.."/git";
            local install_dir = vmake_tool.git.root;
            clean_dir(install_dir);     -- 删除git
            aria2(down_url, down_dir);
            a7z(down_file_path, middle_root_dir);
            move_dir(middle_root_dir, install_dir);
            print("\t\tdebug->the git install success!!!");
        -- elseif term_cmd_conf=="cmake" then
        -- elseif term_cmd_conf=="make" then
        -- elseif term_cmd_conf=="mingw_w64" then
        -- elseif term_cmd_conf=="mingw_llvm" then
        -- elseif term_cmd_conf=="msvc_vsget" then
        -- elseif term_cmd_conf=="msvc_llvm" then
        elseif term_cmd_conf=="vcpkg" then
            local down_file = vmake_tool.vcpkg.download_file;
            local down_file_path = vmake_tool.aria2.cache.."/"..down_file;
            local down_url = vmake_tool.vcpkg.download_url;
            local down_dir = vmake_tool.aria2.cache;
            local unzip_dir = vmake_tool.a7z.cache;
            local middle_root_dir = vmake_tool.a7z.cache.."/"..string.sub(vmake_tool.vcpkg.download_file,1,-5);  -- 解压后的根路径
            local install_dir = vmake_tool.vcpkg.root;
            clean_dir(install_dir);   -- 删除vcpkg
            aria2(down_url,down_dir);   -- 下载vcpkg
            a7z(down_file_path,unzip_dir);    -- 解压vcpkg
            move_dir(middle_root_dir,install_dir);   -- 移动vcpkg
            system_execute(string.format("%s/bootstrap-vcpkg.bat", vmake_tool.vcpkg.root)); -- 使用官方脚本安装
        end
    end

    print("\tinfo->>>analyze cmd start!!!<<");
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
    print("\tdebug->cmd type:",term_cmd_type);
    print("\tdebug->cmd conf:",term_cmd_conf);
    -- 命令调用
    if term_cmd_type~=nil then
        if (term_cmd_type=="lua") then
            default_vmake_tool(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="luarocks") then
            default_vmake_tool(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="aria2") then
            default_vmake_tool(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="a7z") then
            default_vmake_tool(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="install") then
            term_install(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="list") then
            term_list(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="setEnv" or term_cmd_type=="setenv") then
            term_setEnv(term_cmd_type, term_cmd_conf);
        elseif (term_cmd_type=="help") then
            term_help(term_cmd_type, term_cmd_conf);
        else
            term_help(term_cmd_type, term_cmd_conf);
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
    -- (01)软件相关信息
    vmake_info = {
        name = "vmake",
        version = "v.src",
        author = "vgtxc",
        email = "<email>",
        url = "https://github.com/vgtxc/vmake",
    };
    -- (02)软件所在硬盘路径
    vmake_root = io.popen("cd"):read("*a");
    vmake_root = string.gsub(vmake_root, "\n", "");
    vmake_root = string.gsub(vmake_root, "\\", "/");
    -- 当前项目工作路径
    vmake_work_root = nil;
    -- print("\tdebug->vmake_root software loacation:",vmake_root);
    -- (03)引入第三方库
    lua_module_root = vmake_root .. "/tool/lua/luarocks/lib/lua/5.4/?.dll";
    lua_share_root = vmake_root .. "/tool/lua/luarocks/share/lua/5.4/?.lua";
    -- package.path = lua_share_root;  -- 引入第三方库, 源文件
    -- package.cpath = lua_module_root;    -- 引入第三方库, 动态库
    -- vmake_module = {
    --     lfs = require("lfs"),
    --     penlight = require("pl.path"),
    -- };
    -- (04)配置内置工具
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
            download_url = "https://github.com/microsoft/vcpkg/archive/refs/tags/2025.12.12.zip",
            download_file = "vcpkg-2025.12.12.zip",
            install_flag = false,
            excu = vmake_root .. "/tool/vcpkg/vcpkg.exe",
            root = vmake_root .. "/tool/vcpkg",
            version = "2025.12.12",
            excu_arg = nil,
        },
        -- xmake<通过内置命令下载>
        -- cmake<通过内置命令下载>
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
    -- 判断没有内置的工具是否安装
    for key,valu in pairs(vmake_tool) do
        if (valu.install_flag == false and detect_path(valu.excu)==true) then
            valu.install_flag = true;
        end
    end
    
end

-- 05.软件结束配置
function vmake_over()
    print("info->end config");
end

function main()
    print("info->init vmake!!!");
    -- 软件初始化
    vmake_init();
    -- -- 软件配置分析 
    -- analyze_config();
    -- 命令分析
    analyze_term();
    -- -- 项目配置分析
    -- analyze_proj();
    print("info->over vmake!!!");
    local retval = nil;
    return retval;
end

main() 