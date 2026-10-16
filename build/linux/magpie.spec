#
# spec file for package magpie
#
# Copyright (c) 2026 yetone
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

Name:           magpie
Version:        0.1.1275
Release:        0
Summary:        One place to pick every agent's model
License:        MIT
Group:          Development/Tools/Other
URL:            https://github.com/yetone/magpie
Source0:        %{name}-%{version}.tar.gz
Source1:        magpie.desktop
Source2:        magpie.service

BuildRequires:  golang(API) >= 1.24
BuildRequires:  pkgconfig
BuildRequires:  pkgconfig(gtk+-3.0)
BuildRequires:  pkgconfig(webkit2gtk-4.1)
BuildRequires:  desktop-file-utils
BuildRequires:  hicolor-icon-theme
%{?systemd_ordering}

# Stripped Go binaries do not provide ELF debuginfo for debugedit
%global debug_package %{nil}
%global _build_id_links none

%description
Magpie is an all-in-one model router, proxy, and manager for AI coding
assistants (Claude Code, OpenAI Codex, Gemini CLI, Antigravity, OpenCode,
Cursor, Zed, and more). It provides a native desktop interface and a local
gateway server for managing API keys, subscriptions, token quotas, and routing.

%prep
%setup -q

%build
go build \
    -tags "production gtk3" \
    -trimpath \
    -ldflags="-s -w -X main.version=v%{version}" \
    -o magpie .

# Generate icons in standard freedesktop resolutions
mkdir -p generated-icons
for s in 16 32 48 64 128 256 512; do
    go run build/icon/gen.go app $s "generated-icons/icon_${s}.png"
done

%install
# Install main executable
install -D -p -m 0755 magpie %{buildroot}%{_bindir}/magpie

# Install XDG desktop entry
install -D -p -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/applications/magpie.desktop

# Install systemd user service
install -D -p -m 0644 %{SOURCE2} %{buildroot}%{_userunitdir}/magpie.service

# Install vector icon
install -D -p -m 0644 build/icon/magpie.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/magpie.svg

# Install raster icons
for s in 16 32 48 64 128 256 512; do
    install -D -p -m 0644 "generated-icons/icon_${s}.png" \
        "%{buildroot}%{_datadir}/icons/hicolor/${s}x${s}/apps/magpie.png"
done

%check
%{buildroot}%{_bindir}/magpie --version
desktop-file-validate %{buildroot}%{_datadir}/applications/magpie.desktop

%post
%{?systemd_user_post:%systemd_user_post %{name}.service}

%preun
%{?systemd_user_preun:%systemd_user_preun %{name}.service}

%postun
%{?systemd_user_postun_with_restart:%systemd_user_postun_with_restart %{name}.service}

%files
%license LICENSE
%doc README.md README.zh-CN.md
%{_bindir}/magpie
%{_datadir}/applications/magpie.desktop
%{_userunitdir}/magpie.service
%{_datadir}/icons/hicolor/*/apps/magpie.*
