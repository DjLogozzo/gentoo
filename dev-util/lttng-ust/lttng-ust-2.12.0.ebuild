# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

MY_P="${P/_rc/-rc}"
MY_SLOT="$(ver_cut 1-2)"

DESCRIPTION="Linux Trace Toolkit - UST library"
HOMEPAGE="https://lttng.org"
SRC_URI="https://lttng.org/files/${PN}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0/${MY_SLOT}"
KEYWORDS="amd64 arm arm64 ~hppa ~ia64 ppc ppc64 sparc ~x86"
IUSE="examples numa"

DEPEND="
	dev-libs/userspace-rcu:=
	numa? ( sys-process/numactl )"
RDEPEND="${DEPEND}"

S="${WORKDIR}"/${MY_P}

src_prepare() {
	default
	if ! use examples; then
		sed -i -e '/SUBDIRS/s:examples::' doc/Makefile.am || die
	fi
	eautoreconf
}

src_configure() {
	econf $(use_enable numa)
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die
}
