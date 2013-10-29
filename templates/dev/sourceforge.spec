Name:        packagename
Version:     0.0.1
Release:     1%{?dist}
Summary:     short summary

License:     GPLv3
URL:         https://sourceforge.net/projects/%{name}/
Source0:     http://downloads.sf.net/%{name}/%{name}-%{version}.tar.gz

BuildArch:   noarch


%description
%summary


%prep
%setup -q -c %{name}-%{version}


%build
# nothing to do


%install
rm -rf       %{buildroot}
mkdir -p     %{buildroot}%{_datadir}/%{name}
mv %{name}/* %{buildroot}%{_datadir}/%{name}/


%check
desktop-file-validate %{buildroot}/%{_datadir}/applications/%{name}.desktop


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)   
%doc %{_datadir}/%{name}/README
%{_datadir}/%{name}


%changelog

