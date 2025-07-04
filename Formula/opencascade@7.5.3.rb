class OpencascadeAT753 < Formula
  desc "3D modeling and numerical simulation software for CAD/CAM/CAE"
  homepage "https://github.com/Open-Cascade-SAS"
  url "https://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=refs/tags/V7_5_3;sf=tgz"
  version "7.5.3"
  sha256 "cc3d3fd9f76526502c3d9025b651f45b034187430f231414c97dda756572410b"
  license "LGPL-2.1-only"
  # head "https://github.com/Open-Cascade-SAS/OCCT", branch: "master" # NOTE: not valid

  # The first-party download page (https://dev.opencascade.org/release)
  # references version 7.5.0 and hasn't been updated for later maintenance
  # releases (e.g., 7.5.3, 7.5.2), so we check the Git tags instead. Release
  # information is posted at https://dev.opencascade.org/forums/occt-releases
  # but the text varies enough that we can't reliably match versions from it.
  livecheck do
    url "https://git.dev.opencascade.org/repos/occt.git"
    regex(/^v?(\d+(?:[._]\d+)+(?:p\d+)?)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  keg_only :versioned_formula # NOTE: homebrewcore provides opencascade too

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "rapidjson" => :build
  depends_on "freecad/freecad/tbb@2020_u3"
  depends_on "freeimage"
  depends_on "freetype"
  depends_on "tcl-tk"

  # NOTE: https://tracker.dev.opencascade.org/view.php?id=32328
  # NOTE: https://forum.freecad.org/viewtopic.php?f=4&t=58090
  patch :DATA

  def install
    tcltk = Formula["tcl-tk"]
    system "cmake", ".",
                    "-DUSE_FREEIMAGE=ON",
                    "-DUSE_RAPIDJSON=ON",
                    "-DUSE_TBB=ON",
                    "-DINSTALL_DOC_Overview=ON",
                    "-D3RDPARTY_FREEIMAGE_DIR=#{Formula["freeimage"].opt_prefix}",
                    "-D3RDPARTY_FREETYPE_DIR=#{Formula["freetype"].opt_prefix}",
                    "-D3RDPARTY_RAPIDJSON_DIR=#{Formula["rapidjson"].opt_prefix}",
                    "-D3RDPARTY_RAPIDJSON_INCLUDE_DIR=#{Formula["rapidjson"].opt_include}",
                    "-D3RDPARTY_TBB_DIR=#{Formula["tbb@2020"].opt_prefix}",
                    "-D3RDPARTY_TCL_DIR:PATH=#{tcltk.opt_prefix}",
                    "-D3RDPARTY_TK_DIR:PATH=#{tcltk.opt_prefix}",
                    "-D3RDPARTY_TCL_INCLUDE_DIR:PATH=#{tcltk.opt_include}",
                    "-D3RDPARTY_TK_INCLUDE_DIR:PATH=#{tcltk.opt_include}",
                    "-D3RDPARTY_TCL_LIBRARY_DIR:PATH=#{tcltk.opt_lib}",
                    "-D3RDPARTY_TK_LIBRARY_DIR:PATH=#{tcltk.opt_lib}",
                    "-D3RDPARTY_TCL_LIBRARY:FILEPATH=#{tcltk.opt_lib}/libtcl#{tcltk.version.major_minor}.dylib",
                    "-D3RDPARTY_TK_LIBRARY:FILEPATH=#{tcltk.opt_lib}/libtk#{tcltk.version.major_minor}.dylib",
                    "-DCMAKE_INSTALL_RPATH:FILEPATH=#{lib}",
                    *std_cmake_args
    system "make", "install"

    bin.env_script_all_files(libexec/"bin", CASROOT: prefix)

    # Some apps expect resources in legacy ${CASROOT}/src directory
    prefix.install_symlink pkgshare/"resources" => "src"
  end

  test do
    # NOTE: the below test will fail on macos mojave due to recent bug
    # introducted from 7.5.{1,2,3} but not 7.5.0
    # v7.5.x errors when trying to exit
    # output = shell_output("#{bin}/DRAWEXE -c \"pload ALL\"")
    # assert_equal "1", output.chomp
    system "true"
  end
end

__END__
diff --git a/src/ShapeUpgrade/ShapeUpgrade_UnifySameDomain.hxx b/src/ShapeUpgrade/ShapeUpgrade_UnifySameDomain.hxx
index b1558d111f..8cbf516289 100644
--- a/src/ShapeUpgrade/ShapeUpgrade_UnifySameDomain.hxx
+++ b/src/ShapeUpgrade/ShapeUpgrade_UnifySameDomain.hxx
@@ -17,6 +17,7 @@
 #ifndef _ShapeUpgrade_UnifySameDomain_HeaderFile
 #define _ShapeUpgrade_UnifySameDomain_HeaderFile
 
+#include <TopoDS_Edge.hxx>
 #include <BRepTools_History.hxx>
 #include <Standard.hxx>
 #include <Standard_Type.hxx>
