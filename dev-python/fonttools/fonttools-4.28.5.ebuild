# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )
PYTHON_REQ_USE="xml(+)"

inherit distutils-r1 virtualx

DESCRIPTION="Library for manipulating TrueType, OpenType, AFM and Type1 fonts"
HOMEPAGE="https://github.com/fonttools/fonttools/"
SRC_URI="https://github.com/fonttools/fonttools/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ppc ppc64 ~riscv sparc x86 ~x64-macos"

RDEPEND=">=dev-python/fs-2.4.9[${PYTHON_USEDEP}]"
BDEPEND="
	${RDEPEND}
	dev-python/cython[${PYTHON_USEDEP}]
	test? (
		app-arch/brotli[python,${PYTHON_USEDEP}]
		app-arch/zopfli
	)"

distutils_enable_tests pytest

python_prepare_all() {
	# When dev-python/pytest-shutil is installed, we get weird import errors.
	# This is due to incomplete nesting in the Tests/ tree:
	#
	#   Tests/feaLib/__init__.py
	#   Tests/ufoLib/__init__.py
	#   Tests/svgLib/path/__init__.py
	#   Tests/otlLib/__init__.py
	#   Tests/varLib/__init__.py
	#
	# This tree requires an __init__.py in Tests/svgLib/ too, bug #701148.
	touch Tests/svgLib/__init__.py || die

	distutils-r1_python_prepare_all
}

src_configure() {
	DISTUTILS_ARGS=( --with-cython )
}

python_test() {
	distutils_install_for_testing
	# virtualx used when matplotlib is installed causing plot module tests to run
	virtx epytest Tests fontTools
}
