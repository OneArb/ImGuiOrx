-- This premake script should be used with orx-customized version of premake4.
-- Its Hg repository can be found at https://bitbucket.org/orx/premake-stable.
-- A copy, including binaries, can also be found in the extern/premake folder.

--
-- Globals
--

function initconfigurations ()
    return
    {
        "Debug",
        "Release",
    }
end

function initplatforms ()
    if os.is ("windows") then
        if string.lower(_ACTION) == "vs2013"
        or string.lower(_ACTION) == "vs2015"
        or string.lower(_ACTION) == "vs2017" then
            return
            {
                "x64",
                "x32"
            }
        else
            return
            {
                "Native"
            }
        end
    elseif os.is ("linux") then
        if os.is64bit () then
            return
            {
                "x64",
                "x32"
            }
        else
            return
            {
                "x32",
                "x64"
            }
        end
    elseif os.is ("macosx") then
        if string.find(string.lower(_ACTION), "xcode") then
            return
            {
                "Universal"
            }
        else
            return
            {
                "x32", "x64"
            }
        end
    end
end

function defaultaction (name, action)
   if os.is (name) then
      _ACTION = _ACTION or action
   end
end

defaultaction ("windows", "vs2017")
defaultaction ("linux", "gmake")
defaultaction ("macosx", "gmake")

newoption
{
    trigger = "to",
    value   = "path",
    description = "Set the output location for the generated files"
}

if os.is ("macosx") then
    osname = "mac"
else
    osname = os.get()
end

destination = _OPTIONS["to"] or "./" .. osname .. "/" .. _ACTION
copybase = path.rebase ("..", os.getcwd (), os.getcwd () .. "/" .. destination)


--
-- Solution: imgui_orx
--

solution "imgui_orx"

    language ("C++")

    location (destination)

    configurations
    {
        initconfigurations ()
    }

    platforms
    {
        initplatforms ()
    }

    includedirs
    {
        "../include",
		"../imgui",
        os.getenv('ORX').."/include",
    }

    excludes {}

    flags
    {
        "NoPCH",
        "NoManifest",
        "FloatFast",
        "NoNativeWChar",
        "NoExceptions",
        "NoIncrementalLink",
        "NoEditAndContinue",
        "NoMinimalRebuild",
        "Symbols",
        "StaticRuntime"
    }

    configuration {"not vs2013", "not vs2015", "not vs2017"}
        flags {"EnableSSE2"}

    configuration {"not x64"}
        flags {"EnableSSE2"}

    configuration {"not windows"}
        flags {"Unicode"}

    configuration {"*Debug*"}
        targetsuffix ("d")
        defines {"__orxDEBUG__"}

    configuration {"*Release*"}
        flags {"Optimize", "NoRTTI"}


-- Linux

    configuration {"linux", "x32"}
        libdirs {}
        buildoptions { "-Wno-unused-function", "-Wno-unused-but-set-variable" }

    configuration {"linux", "x64"}
        libdirs {}
        buildoptions { "-Wno-unused-function", "-Wno-unused-but-set-variable" }


-- Mac OS X

    configuration {"macosx"}
        libdirs { }
        buildoptions { "-x c++", "-gdwarf-2", "-Wno-write-strings", "-fvisibility-inlines-hidden" }
        linkoptions { "-dead_strip" }

    configuration {"macosx", "x32"}
        buildoptions { "-mfix-and-continue" }


-- Windows

    configuration {"windows", "vs*"}
        buildoptions { "/MP" }

--
-- Project: imgui_orx_test
--

project "imgui_orx_lib"

    files
    {
        "../src/**.cpp",
        "../src/**.c",
        "../include/**.h",
        "../imgui/*.cpp",
        "../imgui/*.h"
    }

    targetname ("imgui_orx")

    -- Work around for codelite "default" configuration
    configuration {"codelite"}
        kind ("StaticLib")

    configuration {}
        targetdir ("../lib/static")
        kind ("StaticLib")

    configuration {"not xcode*", "*Core*"}
        targetdir ("../lib/static")
        kind ("StaticLib")


-- Linux

    configuration {"linux"}
        buildoptions {"-fPIC", "-std=c++11"}
        defines {"_GNU_SOURCE"}
		

-- Mac OS X

    configuration {"macosx", "not codelite", "not codeblocks"}
        links
        {
            "Foundation.framework",
            "IOKit.framework",
            "AppKit.framework",
        }

    configuration {"macosx", "codelite or codeblocks"}
        linkoptions
        {
            "-framework Foundation",
            "-framework IOKit",
            "-framework AppKit",
        }

    configuration { "macosx" }
        links { }

    configuration{"macosx"}
        buildoptions { "-Wno-deprecated-declarations", "-Wno-empty-body", "-std=c++11" }

    configuration {"macosx", "*Debug*"}
        linkoptions {"-install_name @executable_path/libimguiorxd.dylib"}

    configuration {"macosx", "*Release*"}
        linkoptions {"-install_name @executable_path/libimguiorx.dylib"}


-- Windows

    configuration {"windows"}
        links {}


		
		
		
		
		
		
		
project "imgui_orx_test"
    files {"../test/main.cpp"}

    targetdir ("../bin")

    kind ("ConsoleApp")

    configuration {"not xcode*", "*Core*"}
        defines {"__orxSTATIC__"}


-- Linux

    configuration {"linux"}
		links { "../lib/static/imgui_orxd", os.getenv('ORX').."/lib/dynamic/orxd", }
        linkoptions {"-Wl,-rpath ./", "-Wl,--export-dynamic"}
        postbuildcommands 
		{
			"cp -f " .. copybase .. "/test/*.ini " .. copybase .. "/bin",
			"cp -f " .. os.getenv('ORX').."/lib/dynamic/*.so " .. copybase .. "/bin"
		}

    -- This prevents an optimization bug from happening with some versions of gcc on linux
    configuration {"linux", "not *Debug*"}
		links { "../lib/static/imgui_orx", os.getenv('ORX').."/lib/dynamic/orx" }
        buildoptions {"-fschedule-insns"}
        postbuildcommands 
		{
			"cp -f " .. copybase .. "/test/*.ini " .. copybase .. "/bin",
			"cp -f " .. os.getenv('ORX').."/lib/dynamic/*.so " .. copybase .. "/bin"
		}


-- Mac OS X

    configuration {"macosx", "gmake", "*Core*"}
        links
        {
            "Foundation.framework",
            "IOKit.framework",
            "AppKit.framework",
            "pthread"
        }
        postbuildcommands 
		{
			"cp -f " .. copybase .. "/test/*.ini " .. copybase .. "/bin",
			"cp -f " .. os.getenv('ORX').."/lib/dynamic/*.so " .. copybase .. "/bin"
		}

    configuration {"macosx", "codelite or codeblocks", "*Core*"}
        linkoptions
        {
            "-framework Foundation",
            "-framework IOKit",
            "-framework AppKit"
        }
        links
        {
            "pthread"
        }
        postbuildcommands 
		{
			"cp -f " .. copybase .. "/test/*.ini " .. copybase .. "/bin",
			"cp -f " .. os.getenv('ORX').."/lib/dynamic/*.so " .. copybase .. "/bin"
		}


-- Windows

    configuration {"windows", "Debug"}
        implibdir ("../lib/static")
        implibname ("imporx")
        implibextension (".lib")
        links
        {
			"../lib/static/imgui_orxd",
			os.getenv('ORX').."/lib/dynamic/orxd",
            "winmm"
        }
        postbuildcommands 
		{
			"cmd /c copy /Y " .. path.translate(copybase, "\\") .. "\\test\\*.ini " .. path.translate(copybase, "\\") .. "\\bin",
			"cmd /c copy /Y " .. os.getenv('ORX').."\\lib\\dynamic\\orx*.dll " .. path.translate(copybase, "\\") .. "\\bin"
		}

	configuration {"windows", "Release"}
        implibdir ("../lib/static")
        implibname ("imporx")
        implibextension (".lib")
        links
        {
			"../lib/static/imgui_orx",
			os.getenv('ORX').."/lib/dynamic/orx",
            "winmm"
        }
        postbuildcommands 
		{
			"cmd /c copy /Y " .. path.translate(copybase, "\\") .. "\\test\\*.ini " .. path.translate(copybase, "\\") .. "\\bin",
			"cmd /c copy /Y " .. os.getenv('ORX').."\\lib\\dynamic\\orx*.dll " .. path.translate(copybase, "\\") .. "\\bin"
		}
