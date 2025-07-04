class FcBundle < Formula
  desc "Meta formula for bundling needed python modules"
  homepage "https://freecad.org/"
  # Dummy URL since no source is being downloaded
  url "file:///dev/null"
  version "0.21.1"

  # sha of file:///dev/null
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

  bottle do
    root_url "https://ghcr.io/v2/freecad/freecad"
    rebuild 5
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "746b5ae6097b318cfcd2af76ab2cc299e5b482d4f30f51aa6feda5a0d8c5a0d2"
    sha256 cellar: :any_skip_relocation, ventura:      "ae747a56360eceea2015dc1d16e0bb05a26772237cf0c769dab927821cd52270"
    sha256 cellar: :any_skip_relocation, monterey:     "ff6664bbbc655449324f058485e870a3fcb9d257a3ed73f111d1c274c502f05d"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "e4727d08d25dd793c1b2460dd2e60eaa7be5fb82e9af4fdcb3b82044b35a2d6e"
  end

  depends_on "freecad/freecad/coin3d_py310"
  depends_on "freecad/freecad/numpy@1.26.4_py310"
  depends_on "freecad/freecad/pyside2@5.15.11_py310"
  depends_on "freecad/freecad/shiboken2@5.15.11_py310"

  resource "six" do
    url "https://files.pythonhosted.org/packages/71/39/171f1c67cd00715f190ba0b100d606d440a28c93c7714febeca8b79af85e/six-1.16.0.tar.gz"
    sha256 "1e61c37477a1626458e36f7b1d82aa5c9b094fa4802892072e49de9c60c4c926"
  end

  def install
    # explicitly set python version
    pyver = "3.10"

    venv_dir = libexec/"vendor"

    # Create a virtual environment
    system "python3.10", "-m", "venv", venv_dir
    venv_pip = venv_dir/"bin/pip"

    # Install the six module using pip in the virtual environment
    # certain freecad workbenches require the python six module
    resource("six").stage do
      system venv_pip, "install", "."
    end

    # Read the contents of the .pth file into a variable
    # shiboken2_pth_contents = \
    # File.read("#{Formula["shiboken2@5.15.11"].opt_prefix}/lib/python#{pyver}/site-packages/shiboken2.pth").strip

    pyside2_pth_contents =
      File.read("#{Formula["pyside2@5.15.11_py310"].opt_prefix}/lib/python#{pyver}/pyside2.pth").strip

    coin3d_pivy_pth_contents =
      File.read("#{Formula["coin3d_py310"].opt_prefix}/lib/python#{pyver}/coin3d_py310-pivy.pth").strip

    numpy_pth_contents =
      File.read("#{Formula["numpy@1.26.4_py310"].opt_prefix}/lib/python#{pyver}/numpy.pth").strip

    site_packages = Language::Python.site_packages("python3.10")
    # {shiboken2_pth_contents}
    pth_contents = <<~EOS
      #{pyside2_pth_contents}
      #{coin3d_pivy_pth_contents}
      #{numpy_pth_contents}
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
    site_packages_file = prefix/"lib/python3.10/site-packages/freecad-py-modules.pth"
    if site_packages_file.exist?
      puts "Test: OK - freecad-py-modules.pth file exists"
    else
      onoe "Test: Error - freecad-py-modules.pth file not found"
    end
  end
end
