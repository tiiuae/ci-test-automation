===============================================================================
Lib Folder Contents and usage
===============================================================================

The lib folder contains both a static library and a dynamic library, as well
as a folder containing the required library header files.

Mac OS
===============================================================================

On Mac OS, all you would need do is link dynamically to the .framework file,
which contains the headers. Or to link statically, you'd need to include the
headers folder in your include path, and link against the libBrainStem2.a static
library file.

Linux
===============================================================================

On Linux, the dynamic and static libraries have the same prefix 'libBrainStem2,'
This can cause some issues with ld if the library you are trying to use is not
the first one found by ld. To make sure you link against the correct one,
dynamic or static, either change the name of the libBrainStem file you are not
using to something different. or only copy the library you care to use into your
app. Also, make sure you have the headers folder in you include path.

Windows
===============================================================================

Both dynamic and static libraries are included with MS windows.  The Visual
Studio project comes pre-configured with Debug and Release versions that link
against the dll.  Instructions are available in the individual projects to
modify the Visual Studio project to link against the static library.
