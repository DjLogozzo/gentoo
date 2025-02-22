# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
GNOME2_EAUTORECONF="yes"

inherit gnome2 multilib multilib-minimal virtualx

DESCRIPTION="Gimp ToolKit +"
HOMEPAGE="https://www.gtk.org/"

LICENSE="LGPL-2+"
SLOT="3"
IUSE="aqua broadway colord cups examples gtk-doc +introspection sysprof test vim-syntax wayland +X xinerama"
REQUIRED_USE="
	|| ( aqua wayland X )
	xinerama? ( X )
"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

# Upstream wants us to do their job:
# https://bugzilla.gnome.org/show_bug.cgi?id=768662#c1
RESTRICT="test"

# FIXME: introspection data is built against system installation of gtk+:3,
# bug #????
COMMON_DEPEND="
	>=dev-libs/atk-2.32.0[introspection?,${MULTILIB_USEDEP}]
	>=dev-libs/fribidi-0.19.7[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.57.2:2[${MULTILIB_USEDEP}]
	media-libs/fontconfig[${MULTILIB_USEDEP}]
	>=media-libs/harfbuzz-0.9:=
	>=media-libs/libepoxy-1.4[X(+)?,${MULTILIB_USEDEP}]
	virtual/libintl[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.14[aqua?,glib,svg,X?,${MULTILIB_USEDEP}]
	>=x11-libs/gdk-pixbuf-2.30:2[introspection?,${MULTILIB_USEDEP}]
	>=x11-libs/pango-1.41.0[introspection?,${MULTILIB_USEDEP}]
	x11-misc/shared-mime-info

	colord? ( >=x11-misc/colord-0.1.9:0=[${MULTILIB_USEDEP}] )
	cups? ( >=net-print/cups-2.0[${MULTILIB_USEDEP}] )
	introspection? ( >=dev-libs/gobject-introspection-1.39:= )
	sysprof? ( >=dev-util/sysprof-capture-3.33.2:3[${MULTILIB_USEDEP}] )
	wayland? (
		>=dev-libs/wayland-1.14.91[${MULTILIB_USEDEP}]
		>=dev-libs/wayland-protocols-1.17
		media-libs/mesa[wayland,${MULTILIB_USEDEP}]
		>=x11-libs/libxkbcommon-0.2[${MULTILIB_USEDEP}]
	)
	X? (
		>=app-accessibility/at-spi2-atk-2.15.1[${MULTILIB_USEDEP}]
		media-libs/mesa[X(+),${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXcomposite[${MULTILIB_USEDEP}]
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXdamage[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXfixes[${MULTILIB_USEDEP}]
		>=x11-libs/libXi-1.3[${MULTILIB_USEDEP}]
		>=x11-libs/libXrandr-1.5[${MULTILIB_USEDEP}]
		xinerama? ( x11-libs/libXinerama[${MULTILIB_USEDEP}] )
	)
"
DEPEND="${COMMON_DEPEND}
	test? (
		media-fonts/font-cursor-misc
		media-fonts/font-misc-misc
	)
	X? ( x11-base/xorg-proto )
"
# gtk+-3.2.2 breaks Alt key handling in <=x11-libs/vte-0.30.1:2.90
# gtk+-3.3.18 breaks scrolling in <=x11-libs/vte-0.31.0:2.90
RDEPEND="${COMMON_DEPEND}
	>=dev-util/gtk-update-icon-cache-3
	!<x11-libs/vte-0.31.0:2.90
"
# librsvg for svg icons (PDEPEND to avoid circular dep), bug #547710
PDEPEND="
	gnome-base/librsvg[${MULTILIB_USEDEP}]
	>=x11-themes/adwaita-icon-theme-3.14
	vim-syntax? ( app-vim/gtk-syntax )
"
BDEPEND="
	app-text/docbook-xml-dtd:4.1.2
	app-text/docbook-xsl-stylesheets
	dev-libs/gobject-introspection-common
	dev-libs/libxslt
	>=dev-util/gdbus-codegen-2.48
	dev-util/glib-utils
	>=dev-util/gtk-doc-am-1.20
	wayland? ( dev-util/wayland-scanner )
	>=sys-devel/gettext-0.19.7
	virtual/pkgconfig
	x11-libs/gdk-pixbuf:2
	gtk-doc? (
		app-text/docbook-xml-dtd:4.3
		>=dev-util/gtk-doc-1.20
	)
"

MULTILIB_CHOST_TOOLS=(
	/usr/bin/gtk-query-immodules-3.0$(get_exeext)
)

PATCHES=(
	# gtk-update-icon-cache is installed by dev-util/gtk-update-icon-cache
	"${FILESDIR}"/${PN}-3.24.25-update-icon-cache.patch

	# Fix broken autotools logic
	"${FILESDIR}"/${PN}-3.22.20-libcloudproviders-automagic.patch
)

strip_builddir() {
	local rule=$1
	shift
	local directory=$1
	shift
	sed -e "s/^\(${rule} =.*\)${directory}\(.*\)$/\1\2/" -i $@ \
		|| die "Could not strip director ${directory} from build."
}

src_prepare() {
	if ! use test ; then
		# don't waste time building tests
		strip_builddir SRC_SUBDIRS testsuite Makefile.{am,in}

		# the tests dir needs to be build now because since commit
		# 7ff3c6df80185e165e3bf6aa31bd014d1f8bf224 tests/gtkgears.o needs to be there
		# strip_builddir SRC_SUBDIRS tests Makefile.{am,in}
	fi

	if ! use examples; then
		# don't waste time building demos
		strip_builddir SRC_SUBDIRS demos Makefile.{am,in}
		strip_builddir SRC_SUBDIRS examples Makefile.{am,in}
	fi

	gnome2_src_prepare
}

multilib_src_configure() {
	local myconf=(
		$(use_enable aqua quartz-backend)
		$(use_enable broadway broadway-backend)
		$(use_enable colord)
		$(use_enable cups cups auto)
		$(multilib_native_use_enable gtk-doc)
		$(multilib_native_use_enable introspection)
		$(use_enable sysprof profiler)
		$(use_enable wayland wayland-backend)
		$(use_enable X x11-backend)
		$(use_enable X xcomposite)
		$(use_enable X xdamage)
		$(use_enable X xfixes)
		$(use_enable X xkb)
		$(use_enable X xrandr)
		$(use_enable xinerama)
		# cloudprovider is not packaged in Gentoo yet
		--disable-cloudproviders
		--disable-papi
		--enable-man
		--with-xml-catalog="${EPREFIX}"/etc/xml/catalog
		# need libdir here to avoid a double slash in a path that libtool doesn't
		# grok so well during install (// between $EPREFIX and usr ...)
		# TODO: Is this still the case?
		--libdir="${EPREFIX}"/usr/$(get_libdir)
		CUPS_CONFIG="${EPREFIX}/usr/bin/${CHOST}-cups-config"
	)

	if use wayland; then
		myconf+=(
			# Include wayland immodule into gtk itself, to avoid problems like
			# https://gitlab.gnome.org/GNOME/gnome-shell/issues/109 from a
			# user overridden GTK_IM_MODULE envvar
			--with-included-immodules=wayland
		)
	fi;

	ECONF_SOURCE=${S} gnome2_src_configure "${myconf[@]}"

	# work-around gtk-doc out-of-source brokedness
	if multilib_is_native_abi; then
		local d
		for d in gdk gtk libgail-util; do
			ln -s "${S}"/docs/reference/${d}/html docs/reference/${d}/html || die
		done
	fi
}

multilib_src_test() {
	"${EROOT}${GLIB_COMPILE_SCHEMAS}" --allow-any-name "${S}/gtk" || die
	GSETTINGS_SCHEMA_DIR="${S}/gtk" virtx emake check
}

multilib_src_install() {
	gnome2_src_install
}

multilib_src_install_all() {
	insinto /etc/gtk-3.0
	doins "${FILESDIR}"/settings.ini
	# Skip README.{in,commits,win32} that would get installed by default
	DOCS=( AUTHORS ChangeLog NEWS README )
	einstalldocs
}

pkg_preinst() {
	gnome2_pkg_preinst

	multilib_pkg_preinst() {
		# Make immodules.cache belongs to gtk+ alone
		local cache="/usr/$(get_libdir)/gtk-3.0/3.0.0/immodules.cache"

		if [[ -e ${EROOT}${cache} ]]; then
			cp "${EROOT}${cache}" "${ED}${cache}" || die
		else
			touch "${ED}${cache}" || die
		fi
	}
	multilib_parallel_foreach_abi multilib_pkg_preinst
}

pkg_postinst() {
	gnome2_pkg_postinst

	multilib_pkg_postinst() {
		gnome2_query_immodules_gtk3 \
			|| die "Update immodules cache failed (for ${ABI})"
	}
	multilib_parallel_foreach_abi multilib_pkg_postinst

	if ! has_version "app-text/evince"; then
		elog "Please install app-text/evince for print preview functionality."
		elog "Alternatively, check \"gtk-print-preview-command\" documentation and"
		elog "add it to your settings.ini file."
	fi
}

pkg_postrm() {
	gnome2_pkg_postrm

	if [[ -z ${REPLACED_BY_VERSION} ]]; then
		multilib_pkg_postrm() {
			rm -f "${EROOT}/usr/$(get_libdir)/gtk-3.0/3.0.0/immodules.cache"
		}
		multilib_foreach_abi multilib_pkg_postrm
	fi
}
