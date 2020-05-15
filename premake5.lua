newoption {
    trigger     = "sdl-include-path",
    value       = "path",
    description = "The location of your SDL2 header files"
}

newoption {
    trigger     = "sdl-link-path",
    value       = "path",
    description = "The location of your SDL2 link libraries"
}

newoption {
    trigger     = "use-sdl-framework",
    description = "Use the installed SDL2 framework (on MacOS)"
}

local projectlocation = os.getcwd()
local gl3wlocation = path.join(os.getcwd(), "dependencies/gl3w")

local imguiminimumlocation = path.join(projectlocation, "dependencies/imgui-1.64")
local imguilatestlocation = path.join(projectlocation, "dependencies/imgui-1.76")

if _ACTION then
    projectlocation = path.join(projectlocation, "build", _ACTION)
end

function imguiproject(projectname, imguilocation)
    project(projectname)
    location(projectlocation)
    kind "StaticLib"
    language "C++"
    cppdialect "C++98"
    targetdir "lib/%{cfg.buildcfg}"
    files { path.join(imguilocation, "**.cpp") }
    includedirs {
        imguilocation,
        path.join(gl3wlocation, "include") }

    if _OPTIONS["sdl-include-path"] then
        includedirs { _OPTIONS["sdl-include-path"] }
    end

    if _OPTIONS["use-sdl-framework"] then
        includedirs { "/Library/Frameworks/SDL2.framework/Headers" }
    end
end

function imnodesproject(name, imguilocation)
    project(name)
    location(projectlocation)
    kind "StaticLib"
    language "C++"
    cppdialect "C++98"
    enablewarnings { "all" }
    targetdir "lib/%{cfg.buildcfg}"
    files { "imnodes.h", "imnodes.cpp" }
    includedirs { imguilocation }
end

function exampleproject(name, example_file, imnodesproject, imguiproject, imguilocation)
    project(name)
    location(projectlocation)
    kind "ConsoleApp"
    language "C++"
    cppdialect "C++11"
    targetdir "bin/%{cfg.buildcfg}"
    debugdir "bin/%{cfg.buildcfg}"
    files {"example/main.cpp", path.join("example", example_file) }
    includedirs {
        os.getcwd(),
        imguilocation,
        path.join(gl3wlocation, "include")
    }
    links { "gl3w", imguiproject, imnodesproject }

    if _OPTIONS["sdl-include-path"] then
        includedirs { _OPTIONS["sdl-include-path"] }
    end

    if _OPTIONS["sdl-link-path"] then
        libdirs { _OPTIONS["sdl-link-path"] }

        filter "system:macosx"
            links {
                "iconv",
                "AudioToolbox.framework",
                "Carbon.framework",
                "Cocoa.framework",
                "CoreAudio.framework",
                "CoreVideo.framework",
                "ForceFeedback.framework",
                "IOKit.framework"
            }
        filter "*"
    end

    if _OPTIONS["use-sdl-framework"] then
        includedirs { "/Library/Frameworks/SDL2.framework/Headers" }
        linkoptions { "-F/Library/Frameworks -framework SDL2 -framework CoreFoundation" }
    else
        links { "SDL2" }
    end

    filter "system:windows"
        defines { "SDL_MAIN_HANDLED" }
        links { "opengl32" }
        if _OPTIONS["sdl-link-path"] then
            postbuildcommands { 
                "{COPY} " .. 
                path.join(os.getcwd(), _OPTIONS["sdl-link-path"].."/../bin/", "SDL2.dll") .. 
                " %{cfg.targetdir}" }
        end

    filter "system:linux"
        links { "dl" }
end

workspace "imnodes"
    configurations { "Debug", "Release" }
    architecture "x86_64"
    defines { "IMGUI_DISABLE_OBSOLETE_FUNCTIONS" }

    filter "configurations:Debug"
        symbols "On"

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "On"

    filter "action:vs*"
        defines { "_CRT_SECURE_NO_WARNINGS" }

    warnings "Extra"

    startproject "colornode"

    group "dependencies"

    project "gl3w"
        location(projectlocation)
        kind "StaticLib"
        language "C"
        targetdir "lib/%{cfg.buildcfg}"
        files { path.join(gl3wlocation, "src/gl3w.c") }
        includedirs { path.join(gl3wlocation, "include") }

    imguiproject("imgui-minimum", imguiminimumlocation)

    imguiproject("imgui-latest", imguilatestlocation)

    group "imnodes"

    imnodesproject("imnodes-minimum", imguiminimumlocation)

    imnodesproject("imnodes", imguilatestlocation)

    group "examples"

    exampleproject("simple", "simple.cpp", "imnodes", "imgui-latest", imguilatestlocation)

    exampleproject("saveload", "save_load.cpp", "imnodes", "imgui-latest", imguilatestlocation)

    exampleproject("colornode", "color_node_editor.cpp", "imnodes", "imgui-latest", imguilatestlocation)

    exampleproject("multieditor", "multi_editor.cpp", "imnodes", "imgui-latest", imguilatestlocation)

    exampleproject("simple-minimum", "simple.cpp", "imnodes-minimum", "imgui-minimum", imguiminimumlocation)

    exampleproject("saveload-minimum", "save_load.cpp", "imnodes-minimum", "imgui-minimum", imguiminimumlocation)

    exampleproject("colornode-minimum", "color_node_editor.cpp", "imnodes-minimum", "imgui-minimum", imguiminimumlocation)

    exampleproject("multieditor-minimum", "multi_editor.cpp", "imnodes-minimum", "imgui-minimum", imguiminimumlocation)
