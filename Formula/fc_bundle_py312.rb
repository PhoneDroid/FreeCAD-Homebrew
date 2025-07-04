class FcBundlePy312 < Formula
  desc "Meta formula for bundling needed python modules"
  homepage "https://freecad.org/"
  # Dummy URL since no source is being downloaded
  url "file:///dev/null"
  # this version works with the freecad v1rc2 release thus the 0.9.2 versioning
  version "0.9.2"

  # sha of file:///dev/null
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  revision 2

  bottle do
    root_url "https://ghcr.io/v2/freecad/freecad"
    rebuild 1
    sha256 cellar: :any,                 arm64_sequoia: "102dfe1ca4edbc6f8cc76d870736803f5473476f76fcdc0abc1f88dc12b3f56b"
    sha256 cellar: :any,                 arm64_sonoma:  "538e2622806d029d24e33c7cc585941caa9edcf8e8139045ec9b32b015cc3dbf"
    sha256 cellar: :any,                 ventura:       "3e9b574f9c829c915280f776098abce62c2146c25d1997cc21955ebe430c014c"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "419d965a4c176f1011f84823135ec6b6ed88ad856267ba252e1b7ffc7929c777"
  end

  depends_on "patchelf" => :build
  depends_on "pkgconf" => :build
  # epends_on "brotli" if OS.linux?
  depends_on "freecad/freecad/coin3d@4.0.3_py312"
  depends_on "freecad/freecad/med-file@4.1.1_py312"
  depends_on "freecad/freecad/numpy@2.1.1_py312"
  depends_on "freecad/freecad/pybind11_py312"
  depends_on "freecad/freecad/pyside2@5.15.15_py312" # pyside includes the shiboken2 module as well
  depends_on "freetype"
  # epends_on "libxau" if OS.linux?
  depends_on "libyaml" # reqd by pyyaml
  depends_on "webp" if OS.linux?
  # epends_on "pillow" if OS.linux?

  resource "six" do
    url "https://files.pythonhosted.org/packages/71/39/171f1c67cd00715f190ba0b100d606d440a28c93c7714febeca8b79af85e/six-1.16.0.tar.gz"
    sha256 "1e61c37477a1626458e36f7b1d82aa5c9b094fa4802892072e49de9c60c4c926"
  end

  resource "matplotlib" do
    url "https://files.pythonhosted.org/packages/68/dd/fa2e1a45fce2d09f4aea3cee169760e672c8262325aa5796c49d543dc7e6/matplotlib-3.10.0.tar.gz"
    sha256 "b886d02a581b96704c9d1ffe55709e49b4d2d52709ccebc4be42db856e511278"
  end

  resource "ply" do
    url "https://files.pythonhosted.org/packages/e5/69/882ee5c9d017149285cab114ebeab373308ef0f874fcdac9beb90e0ac4da/ply-3.11.tar.gz"
    sha256 "00c7c1aaa88358b9c765b6d3000c6eec0ba42abca5351b095321aef446081da3"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/54/ed/79a089b6be93607fa5cdaedf301d7dfb23af5f25c398d5ead2525b063e17/pyyaml-6.0.2.tar.gz"
    sha256 "d584d9ec91ad65861cc08d42e834324ef890a082e591037abe114850ff7bbc3e"
  end

  def install
    # explicitly set python version
    pyver = "3.12"

    venv_dir = libexec/"vendor"

    # Create a virtual environment
    system "python3.12", "-m", "venv", venv_dir
    venv_pip = venv_dir/"bin/pip"

    # Install the six module using pip in the virtual environment
    # certain freecad workbenches require the python six module
    resource("six").stage do
      system venv_pip, "install", "."
    end

    resource("matplotlib").stage do
      (buildpath/"mplsetup.cfg").write <<~EOS
        [libs]
        system_freetype = true
      EOS

      # Set MPLSETUPCFG to point to the custom config
      ENV["MPLSETUPCFG"] = buildpath/"mplsetup.cfg"
      ENV.prepend_path "PKG_CONFIG_PATH", Formula["freetype"].opt_lib/"pkgconfig"
      ENV.prepend_path "PKG_CONFIG_PATH", Formula["webp"].opt_lib/"pkgconfig"

      # Install matplotlib within the virtual environment
      system venv_pip, "install", "."

      lib_path = "#{libexec}/vendor/lib/python3.12/site-packages/pillow.libs"
      if Dir.exist?(lib_path)
        Dir["#{lib_path}/*.so.*"].each do |so|
          system "patchelf", "--set-rpath", lib_path, so
        end
      end
    end

    resource("ply").stage do
      system venv_pip, "install", "."
    end

    resource("pyyaml").stage do
      system venv_pip, "install", "."
    end

    # Example: Read the contents of the .pth file into a variable
    # shiboken2_pth_contents = \
    # File.read("#{Formula["shiboken2@5.15.11"].opt_prefix}/lib/python#{pyver}/site-packages/shiboken2.pth").strip

    coin3d_pivy_pth_contents =
      File.read("#{Formula["coin3d@4.0.3_py312"].opt_prefix}/lib/python#{pyver}/coin3d_py312-pivy.pth").strip
    medfile_pth_contents =
      File.read("#{Formula["med-file@4.1.1_py312"].opt_prefix}/lib/python#{pyver}/medfile.pth").strip
    numpy_pth_contents =
      File.read("#{Formula["numpy@2.1.1_py312"].opt_prefix}/lib/python#{pyver}/numpy.pth").strip
    pybind11_pth_contents = File.read(
      "#{Formula["pybind11_py312"].opt_prefix}/lib/python#{pyver}/site-packages/homebrew-pybind11.pth",
    ).strip
    pyside2_pth_contents =
      File.read("#{Formula["pyside2@5.15.15_py312"].opt_prefix}/lib/python#{pyver}/pyside2.pth").strip

    site_packages = Language::Python.site_packages("python3.12")
    # {shiboken2_pth_contents}
    pth_contents = <<~EOS
      #{coin3d_pivy_pth_contents}
      #{medfile_pth_contents}
      #{numpy_pth_contents}
      #{pybind11_pth_contents}
      #{pyside2_pth_contents}
      #{venv_dir}/lib/python#{pyver}/site-packages
    EOS
    (prefix/site_packages/"freecad-py-modules.pth").write pth_contents
  end

  def caveats
    <<-EOS
    this formula is required to get necessary python runtime deps
    working with freecad
    EOS
  end

  test do
    # TODO: i think a more sane test is importing the python modules
    # Check if the expected site-packages file exists
    site_packages_file = prefix/"lib/python3.12/site-packages/freecad-py-modules.pth"
    if site_packages_file.exist?
      puts "Test: OK - freecad-py-modules.pth file exists"
    else
      onoe "Test: Error - freecad-py-modules.pth file not found"
    end
  end
end
