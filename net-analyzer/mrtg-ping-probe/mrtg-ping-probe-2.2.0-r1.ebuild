# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Addon mrtg contrib for stats ping/loss packets"
HOMEPAGE="http://pwo.de/projects/mrtg/"
SRC_URI="ftp://ftp.pwo.de/pub/pwo/mrtg/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"

BDEPEND="dev-lang/perl"
RDEPEND="
	net-analyzer/mrtg
"

src_prepare() {
	sed -i check-ping-fmt \
		-e 's:#!/usr/local/bin/perl -w:#!/usr/bin/perl -w:' \
		|| die
	sed -i mrtg-ping-probe \
		-e 's:#!/bin/perl:#!/usr/bin/perl:' \
		|| die
}

src_install() {
	dodoc ChangeLog NEWS README TODO mrtg.cfg-ping
	doman mrtg-ping-probe.1
	dobin check-ping-fmt mrtg-ping-probe "${FILESDIR}"/mrtg-ping-cfg
}
