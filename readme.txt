开源项目参考:
	lua: https://www.lua.org/
	luarocks: https://luarocks.org/
	7z: https://github.com/ip7z/7zip
	git: https://git-scm.com/
	wget: https://github.com/rockdaboot/wget2
	aria2: https://github.com/aria2/aria2
	vcpkg: https://github.com/microsoft/vcpkg
	mingw_w64: https://github.com/niXman/mingw-builds-binaries
	mingw_llvm: https://github.com/mstorsjo/llvm-mingw
	msvc_vsget: https://github.com/reksar/vsget
	msvc_llvm: https://github.com/backengineering/llvm-msvc

压缩包内部文件夹结构为
file.zip
	|-dirB
	|---dirC
	|---fileD
	|---fileE
使用者只知道file.zip的路径, 但不知道dirB的具体名称,
希望通过7z命令将dirC, fileD, fileE解压到指定的目标文件夹下
