//lastEdit=>2026.02.24-00:32
//lastEdit=>2026.02.23-23:39
//lastEdit=>2026.02.22-14:00
//lastEdit=>2026.02.21-21:22
//lastEdit=>2026.02.02-16:10
//lastEdit=>2026.01.08-22:56
creat: 2026.01.08

项目核心目的:
	(01)对常见开发工具的安装卸载管理;
	(02)对常见开发文件的快速运行, 编译(借用xmake,CMake等简易编译工具);
	(03)开发环境的快速搭建, 追求便携化开发;

特别鸣谢:
	iflow
	通义千问

项目参考:
	vmake: https://github.com/vgtxc/vmake
	7z: https://github.com/ip7z/7zip
	aria2: https://github.com/aria2/aria2
	pixi: https://github.com/prefix-dev/pixi
	lua: https://www.lua.org/
	luarocks: https://luarocks.org/
	git: https://git-scm.com/
	cmake: https://github.com/Kitware/CMake
	xmake: https://github.com/xmake-io/xmake
	vcpkg: https://github.com/microsoft/vcpkg
	mingw_w64: https://github.com/niXman/mingw-builds-binaries
	mingw_llvm: https://github.com/mstorsjo/llvm-mingw
	msvc: https://visualstudio.microsoft.com/
	msvc_mini: https://github.com/Delphier/MSVC
	msvc_vsget: https://github.com/reksar/vsget
	msvc_portable: https://gist.github.com/mmozeiko/7f3162ec2988e81e56d5c4e22cde9977#file-portable-msvc-py
	msvc_llvm: https://github.com/backengineering/llvm-msvc
	qt: https://www.qt.io/
	qt_mini: https://github.com/martinrotter/qt-minimalistic-builds
	qt_mingw: [void]
	qt_aqt: https://github.com/miurahr/aqtinstall
	dotnet: https://dotnet.microsoft.com/
	nodejs: https://nodejs.org
	python: https://www.python.org/
	python_enbed: https://www.python.org/
	java: https://www.java.com/
	rust: https://www.rust-lang.org/
	golang: https://go.dev/
	zig: https://ziglang.org/
	vlang: https://github.com/vlang/v


下步目标:
	(01)实现项目类型的识别
	(02)实现解释类语言的运行
	(03)实现编译类语言的编译运行
	err->python运行pip报错: 需要强制更新pip后使用
	优化python安装函数, 在python安装完成后运行"python.exe -m pip install --upgrade --force-reinstall pip"

v0.0.1#20260223
	修改bug: 
	01.vmake_cmd.creat_batch(); 添加指定脚本类型开关
	02.vmake_sys.set_vmake_tool_env_gen_shell(); 创建cmd语法的脚本, 而非powershell
	03.修改vmake_sys.print_color();函数的缩进错误
	vmake_sys.set_vmake_tool_env_cat_table();
	vmake_sys.set_vmake_tool_env_gen_table();
	vmake_sys.set_vmake_tool_env_gen_str();
	vmake_sys.set_vmake_tool_env_gen_shell();
	vmake_sys.set_vmake_tool_env_gen_term();
	vmake_cmd.setenv();
	vmake_cmd.creat_batch();
	
v0.0.0#20260222
	支持平台:
	[x64_win]
	实现基本功能:
	(01)实现命令行参数解析
	(02)实现配置文件解析更新
