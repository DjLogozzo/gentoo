# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit gnome.org gnome2-utils meson-multilib multilib xdg

DESCRIPTION="Image loading library for GTK+"
HOMEPAGE="https://gitlab.gnome.org/GNOME/gdk-pixbuf"

LICENSE="LGPL-2.1+"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="+introspection jpeg tiff"

# TODO: For windows/darwin support: shared-mime-info conditional, native_windows_loaders option review
DEPEND="
	>=dev-libs/glib-2.56.0:2[${MULTILIB_USEDEP}]
	x11-misc/shared-mime-info
	>=media-libs/libpng-1.4:0=[${MULTILIB_USEDEP}]
	jpeg? ( virtual/jpeg:0=[${MULTILIB_USEDEP}] )
	tiff? ( >=media-libs/tiff-3.9.2:0=[${MULTILIB_USEDEP}] )
	introspection? ( >=dev-libs/gobject-introspection-1.54:= )
"
RDEPEND="${DEPEND}
	!<x11-libs/gtk+-2.90.4:3
"
BDEPEND="
	app-text/docbook-xsl-stylesheets
	app-text/docbook-xml-dtd:4.3
	dev-libs/glib:2
	dev-libs/libxslt
	dev-util/glib-utils
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"

MULTILIB_CHOST_TOOLS=(
	/usr/bin/gdk-pixbuf-query-loaders$(get_exeext)
)

PATCHES=(
	# Do not run lowmem test on uclibc
	# See https://bugzilla.gnome.org/show_bug.cgi?id=756590
	"${FILESDIR}"/${PN}-2.32.3-fix-lowmem-uclibc.patch
)

src_prepare() {
	xdg_src_prepare
	# This will avoid polluting the pkg-config file with versioned libpng,
	# which is causing problems with libpng14 -> libpng15 upgrade
	# See upstream bug #667068
	# First check that the pattern is present, to catch upstream changes on bumps,
	# because sed doesn't return failure code if it doesn't do any replacements
	grep -q "foreach png: \[ 'libpng16', 'libpng15', 'libpng14', 'libpng13', 'libpng12', 'libpng10' \]" meson.build || die "libpng check order has changed upstream"
	sed -e "s/foreach png: \[ 'libpng16', 'libpng15', 'libpng14', 'libpng13', 'libpng12', 'libpng10' \]/foreach png: \[ 'libpng', 'libpng16', 'libpng15', 'libpng14', 'libpng13', 'libpng12', 'libpng10' \]/" -i meson.build || die
}

multilib_src_configure() {
	local emesonargs=(
		-Dpng=true
		$(meson_use tiff)
		$(meson_use jpeg)
		-Dbuiltin_loaders=png,jpeg
		-Drelocatable=false
		#native_windows_loaders
		-Dinstalled_tests=false
		-Dgio_sniffing=true
		-Dgtk_doc=false
		$(meson_native_use_feature introspection)
		$(meson_native_true man)
	)

	meson_src_configure
}

multilib_src_install_all() {
	einstalldocs
	insinto /usr/share/gtk-doc/html
	doins -r "${S}"/docs/gdk-pixbuf
	doins -r "${S}"/docs/gdk-pixdata
}

pkg_preinst() {
	xdg_pkg_preinst

	multilib_pkg_preinst() {
		# Make sure loaders.cache belongs to gdk-pixbuf alone
		local cache="usr/$(get_libdir)/${PN}-2.0/2.10.0/loaders.cache"

		if [[ -e ${EROOT}/${cache} ]]; then
			cp "${EROOT}"/${cache} "${ED}"/${cache} || die
		else
			touch "${ED}"/${cache} || die
		fi
	}

	multilib_foreach_abi multilib_pkg_preinst
	gnome2_gdk_pixbuf_savelist
}

pkg_postinst() {
	# causes segfault if set, see bug 375615
	unset __GL_NO_DSO_FINALIZER

	xdg_pkg_postinst
	multilib_foreach_abi gnome2_gdk_pixbuf_update
}

pkg_postrm() {
	xdg_pkg_postrm

	if [[ -z ${REPLACED_BY_VERSION} ]]; then
		rm -f "${EROOT}"/usr/lib*/${PN}-2.0/2.10.0/loaders.cache
	fi
}
