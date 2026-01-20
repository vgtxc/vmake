-- lastEdit=>2026.01.08-22:52
-- creat: 2026.01.08
-- (01)软件相关信息
vmake_info = {
    name = "vmake",
    version = "v.src",
    author = "vgtxc",
    email = "<email>",
    url = "https://github.com/vgtxc/vmake",
};
-- (04)配置内置工具
vmake_tool = {
    -- lua<内置>
    lua = {
        url = "https://www.lua.org/",
        download_url = "https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download",
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
        install_flag = true,
        excu = vmake_root .. "/tool/lua/luarocks/luarocks.exe",
        root = vmake_root .. "/tool/lua/luarocks",
        config = vmake_root .. "/tool/lua/luarocks/config.lua",
        version = nil,
        excu_arg = nil,
    },
    -- 7z<内置>
    a7z = {
        url = "https://www.7-zip.org/",
        download_url = "https://www.7-zip.org/a/7z2301-extra.7z",
        install_flag = true,
        excu = vmake_root .. "/tool/a7z/7za.exe",
        root = vmake_root .. "/tool/a7z",
        version = "2501",
        excu_arg = nil,
    },
    -- aria2<内置>
    aria2 = {
        url = "https://aria2.github.io/",
        download_url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip",
        install_flag = true,
        excu = vmake_root .. "/tool/aria2/aria2c.exe",
        root = vmake_root .. "/tool/aria2",
        cache = vmake_root .. "/tool/aria2/cache",
        version = "1.37.0",
        excu_arg = nil,
    },
    -- git<通过内置命令下载>
    git = {
        url = "https://git-scm.com/",
        download_url = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe",
        install_flag = false,
        excu = vmake_root .. "/tool/git/git.exe",
        root = vmake_root .. "/tool/git",
        version = "2.52.0",
        excu_arg = nil,
    },
    -- vcpkg<通过内置命令下载>
    vcpkg = {
        url = "https://github.com/microsoft/vcpkg",
        download_url = "https://github.com/microsoft/vcpkg/archive/refs/tags/2025.12.12.zip",
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
    vmake_tool_format = {
        url = "",
        download_url = "",
        install_flag = false,
        excu = "",
        cache = "",
        root = "",
        package = "",
        include = "",
        lib = "",
        version = "",
    },
};
-- 一些内部自己指向值的分配
vmake_tool.lua.excu_arg = nil;
vmake_tool.luarocks.excu_arg = "--lua-dir="..vmake_tool.lua.root.." --tree="..vmake_tool.luarocks.root;
vmake_tool.a7z.excu_arg = nil;
vmake_tool.aria2.excu_arg = "--dir="..vmake_tool.aria2.cache;
vmake_tool.git.excu_arg = nil;
vmake_tool.vcpkg.excu_arg = nil;
    
-- -- 判断没有内置的工具是否安装
-- for key,valu in pairs(vmake_tool) do
--     if (valu.install_flag==false and io.open(valu.excu, "r")==true) then
--         io.close(valu.excu)
--         valu.install_flag = true
--         print(valu);
--     end
-- end